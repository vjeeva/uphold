module Uphold
  module Transports
    class Local < Transport
      include DateHelper

      def initialize(params)
        super(params)
      end

      def fetch_backup
        file_path = File.join(@path, @filename)
        if File.file?(file_path)
          if @compressed
            tmp_path = File.join(@tmpdir, File.basename(file_path))
            logger.info "Copying '#{file_path}' to '#{tmp_path}'"
            FileUtils.cp(file_path, tmp_path)
            decompress(tmp_path) do |_b|
            end
            File.join(@tmpdir, @folder_within)
          else
            @path
          end
        else
          logger.fatal "No file exists at '#{file_path}'"
          nil
        end
      end

      def self.get_backup_paths(config)
        # Regexes from dates in config
        regexes = Uphold::Files.get_regexes_from_config(config)

        # Top level folder path (without dates)
        general_path = Uphold::Files.get_general_path(config, "/mount-#{config[:transport][:type]}-#{config[:name]}")

        # Objective of any transport is to get the paths of relevant backups given the general path directory
        # and the regexes to match with. Here, we first get all paths in the general directory
        paths = []
        Find.find(general_path) do |path|
          paths << path
        end

        # Now, we filter the paths we got above with the regexes from dates
        paths = Uphold::Files.get_paths_matching_regexes(paths, regexes, config[:engine][:settings][:extension])

        # Stripping out mount prefix and adding date key
        array = []
        paths.each do |path|
          d = {}
          d[:backup] = path.gsub!("/mount-#{config[:transport][:type]}-#{config[:name]}", '')
          d[:date] = Files.extract_datetime_from_backup_path(config, path)
          array << d
        end
        array
      end

      def self.get_logs
        Dir[File.join(UPHOLD[:logs][:settings][:path], '*')].select { |log| File.basename(log) =~ /^[0-9]{10}/ }.map { |file| File.basename(file) }
      end

      def self.get_log(filename)
        File.join(UPHOLD[:logs][:settings][:path], filename)
      end

      def self.dump_logs
        logger.info "Logs are available locally at #{UPHOLD[:logs][:settings][:path]}, and if mounted correctly, on the host machine at this path."
      end

      def self.touch_state_file(state)
        loc = UPHOLD[:logs][:settings][:path] || '/var/log/uphold'
        FileUtils.touch(File.join(loc, ENV['UPHOLD_LOG_FILENAME'] + '_' + state)) unless ENV['UPHOLD_LOG_FILENAME'].nil?
      end

    end
  end
end
