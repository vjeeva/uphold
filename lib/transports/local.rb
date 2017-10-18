module Uphold
  module Transports
    class Local < Transport
      include DateHelper

      def initialize(params)
        super(params)
      end

      def fetch_backup
        File.join(@path, @filename)
        # Do we really need to copy this? Can't we just stream it?
        # file_path = File.join(@path, @filename)
        # if File.file?(file_path)
        #   tmp_path = File.join(@tmpdir, File.basename(file_path))
        #   logger.info "Copying '#{file_path}' to '#{tmp_path}'"
        #   FileUtils.cp(file_path, tmp_path)
	       #  if @compressed
        #     decompress(tmp_path) do |_b|
        #     end
        #     File.join(@tmpdir, @folder_within)
        #   else
	       #    @tmpdir
        #   end
        # else
        #   logger.fatal "No file exists at '#{file_path}'"
        #   nil
        # end
      end

      def self.get_backup_paths(config)
        # Regexes from dates in config
        regexes = Uphold::Files.get_date_regexes_from_config(config)

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

        # Stripping out mount prefix
        paths_stripped = []
        paths.each do |path|
          paths_stripped << path.gsub!("/mount-#{config[:transport][:type]}-#{config[:name]}", '')
        end
        paths_stripped
      end

      def self.get_logs(config)
        Dir[File.join(config[:logs][:settings][:path], '*')].select { |log| File.basename(log) =~ /^[0-9]{10}/ }.map { |file| File.basename(file) }
      end

      def self.get_log(config, filename)
        File.join(config[:logs][:settings][:path], filename)
      end

    end
  end
end
