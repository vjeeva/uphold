require 'rubygems'
require 'rubygems/package'
require 'bundler/setup'
Bundler.require(:default, :ui)
load 'environment.rb'

module Uphold
  class Ui < ::Sinatra::Base
    include Logging
    set :views, settings.root + '/views'
    set :public_folder, settings.root + '/public'

    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end

      def epoch_to_datetime(epoch)
        Time.at(epoch).utc.to_datetime.strftime(UPHOLD[:ui_datetime])
      end

      def dateTime_to_UI_Format(datetime)
        datetime.strftime(UPHOLD[:ui_datetime])
      end
    end

    before do
      Config.load_engines
      Config.load_transports
      @configs = Config.load_configs
    end

    get '/' do
      @data = backups_with_logs
      logger.debug @data
      erb :index
    end

    get '/run/:slug' do
      @backups = Uphold::Files.backups(@configs[0])
      @dates = []
      @backups.each do |backup|
        @dates << Files.extract_datetime_from_backup_path(@configs[0], backup)
      end
      start_docker_container(params[:slug], @dates.max.strftime('%s'))
      redirect '/'
    end
    

    get '/logs/:filename' do
      @log = File.join('/var/log/uphold', params[:filename])
      erb :log
    end

    post '/api/1.0/backup' do
      # Doubled? Try to make more efficient
      @backups = Uphold::Files.backups(@configs[0])
      @dates = []
      @backups.each do |backup|
        @dates << Files.extract_datetime_from_backup_path(@configs[0], backup)
      end
      start_docker_container(params[:name], @dates.max)
      200
    end

    get '/api/1.0/backups/:name' do
      # get all the runs for the named config
      content_type :json
      @logs = logs[params[:name]]
      if @logs.nil?
        [].to_json
      else
        @logs.to_json
      end
    end

    get '/api/1.0/backups/:name/latest' do
      # get the latest state for the named config
      @logs = logs[params[:name]]
      if @logs.nil?
        'none'
      else
        @logs.first[:state]
      end
    end

    private

    def start_docker_container(slug, timestamp)
      if Docker::Image.exist?("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
        Docker::Image.get("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
      else
        Docker::Image.create('fromImage' => UPHOLD[:docker_container], 'tag' => UPHOLD[:docker_tag])
      end

      volumes = {}
      UPHOLD[:docker_mounts].flatten.each { |m| volumes[m] = { "#{m}" => 'ro' } }

      # this is a hack for when you're working in development on osx
      volumes[UPHOLD[:config_path]] = { '/etc/uphold' => 'ro' }
      volumes[UPHOLD[:docker_log_path]] = { '/var/log/uphold' => 'rw' }

      # Unix sockets when mounted can't have the protocol at the start
      if UPHOLD[:docker_url].include?('unix://')
        without_protocol = UPHOLD[:docker_url].split('unix://')[1]
        volumes[without_protocol] = { "#{without_protocol}" => 'rw' }
      end

      @container = Docker::Container.create(
          'Image' => "#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}",
          'Cmd' => [slug + '.yml'],
          'Volumes' => volumes,
          'Env' => ["UPHOLD_LOG_FILENAME=#{timestamp}_#{slug}", "TARGET_DATE=#{timestamp}"]
      )

      @container.start('Binds' => volumes.map { |v, h| "#{v}:#{h.keys.first}" })
    end

    def logs
      logs = {}
      Uphold::Files.raw_test_logs.each do |log|
        epoch = log.split('_')[0]
        config = log.split('_')[1].gsub!('.log', '')
        state = Uphold::Files.raw_state_files.find { |s| s.include?("#{epoch}_#{config}") }
        if state
          state = state.gsub("#{epoch}_#{config}", '')[1..-1]
        else
          state = 'running'
        end
        logs[config] ||= []
        logs[config] << { epoch: epoch.to_i, state: state, filename: log }
        logs[config].sort_by! { |h| h[:epoch].to_i }.reverse!
      end
      logs
    end

    def backups_with_logs
      log_backup_matchups_all = []
      @configs.each do |config|
        backup_paths = Uphold::Files.backups(config)
        logss = logs[config[:file]]
        backups = []
        backup_paths.each do |path|
          backup = {}
          backup[:date] = Files.extract_datetime_from_backup_path(config, path)
          backup[:backup] = path
          logss.each do |log|
            if log[:epoch].to_s == backup[:date].strftime('%s').to_s
              backup[:log] = log
            end
          end
          backups << backup
        end
        curr_config = {}
        curr_config[:config_file] = config[:file]
        curr_config[:config_name] = config[:name]
        curr_config[:backups] = backups
        log_backup_matchups_all << curr_config
      end
      log_backup_matchups_all
    end

  end
end