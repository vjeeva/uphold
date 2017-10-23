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

      def datetime_to_UI_Format(datetime)
        datetime.strftime(UPHOLD[:ui_datetime])
      end

      def datetime_to_epoch(datetime)
        datetime.strftime('%s')
      end

    end

    before do
      Config.load_engines
      Config.load_transports
      @configs = Config.load_configs
    end

    get '/' do
      @data = backups_with_logs
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

    get '/run/:slug/:date_epoch' do
      config = get_config_from_filename(params[:slug])
      start_docker_container(config, params[:date_epoch])
      redirect '/'
    end

    get '/logs/:filename' do
      @log = UPHOLD[:logs][:klass].get_log(params[:filename])
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

    def start_docker_container(config, timestamp)
      if Docker::Image.exist?("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
        Docker::Image.get("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
      else
        Docker::Image.create('fromImage' => UPHOLD[:docker_container], 'tag' => UPHOLD[:docker_tag])
      end

      volumes = {}
      UPHOLD[:docker_mounts].flatten.each { |m| volumes[m] = { "#{m}" => 'ro' } }
      volumes[UPHOLD[:backup_tmp_path]] = { UPHOLD[:backup_tmp_path] => 'rw' }

      # this is a hack for when you're working in development on osx
      volumes[UPHOLD[:config_path]] = { '/etc/uphold' => 'ro' }
      volumes[UPHOLD[:docker_log_path]] = { '/var/log/uphold' => 'rw' }

      # Unix sockets when mounted can't have the protocol at the start
      if UPHOLD[:docker_url].include?('unix://')
        without_protocol = UPHOLD[:docker_url].split('unix://')[1]
        volumes[without_protocol] = { "#{without_protocol}" => 'rw' }
      end

      # If trigger is local, run this.
      if not config.key?(:trigger) or config[:trigger][:type] == 'local'
        @container = Docker::Container.create(
            'Image' => "#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}",
            'Cmd' => [config[:file] + '.yml'],
            'Volumes' => volumes,
            'Env' => ["UPHOLD_LOG_FILENAME=#{timestamp}_#{config[:file]}", "TARGET_DATE=#{timestamp}"]
        )
        @container.start('Binds' => volumes.map { |v, h| "#{v}:#{h.keys.first}" })
      # Else if the trigger is external (URL) run this
      elsif config[:trigger][:type] == 'external'
        require 'net/http'

        url = URI.parse(config[:trigger][:settings][:url])
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        logger.info 'Triggering External URL'
        logger.info res.body
      end
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
          if logss != nil
            logss.each do |log|
              if log[:epoch].to_s == backup[:date].strftime('%s').to_s
                backup[:log] = log
              end
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

    def get_config_from_filename(filename)
      config = nil
      @configs.each do |cf|
        if cf[:file] == filename
          config = cf
        end
      end
      config
    end

  end
end