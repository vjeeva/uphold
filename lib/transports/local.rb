module Uphold
  module Transports
    class Local < Transport
      def initialize(params)
        super(params)
      end

      def fetch_backup
        file_path = File.join(@path, @filename)
        if File.file?(file_path)
          tmp_path = File.join(@tmpdir, File.basename(file_path))
          logger.info "Copying '#{file_path}' to '#{tmp_path}'"
          FileUtils.cp(file_path, tmp_path)
	        if @compressed
            decompress(tmp_path) do |_b|
            end
            File.join(@tmpdir, @folder_within)
          else
	          @tmpdir
          end
        else
          logger.fatal "No file exists at '#{file_path}'"
          nil
        end
      end

    end
  end
end
