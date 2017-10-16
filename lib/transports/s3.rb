module Uphold
  module Transports
    class S3 < Transport
      require 'aws-sdk'
      include DateHelper

      def initialize(params)
        super(params)
        @region = params[:region]
        @access_key_id = params[:access_key_id]
        @secret_access_key = params[:secret_access_key]
        @bucket = params[:bucket]
      end

      def fetch_backup
        s3 = Aws::S3::Client.new(region: @region, access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        matching_prefix = s3.list_objects(bucket: @bucket, prefix: @path).contents.collect(&:key)
        matching_file = matching_prefix.find { |s3_file| File.fnmatch(@filename, File.basename(s3_file)) }

        File.open(File.join(@tmpdir, File.basename(matching_file)), 'wb') do |file|
          logger.info "Downloading '#{matching_file}' from S3 bucket #{@bucket}"
          s3.get_object({ bucket: @bucket, key: matching_file }, target: file)
          if @compressed
            decompress(file) do |_b|
            end
          end
	      end
        if @compressed  
	        File.join(@tmpdir, @folder_within)
        else
          @tmpdir
        end
      end

      def self.get_backup_paths(config)
        region = config[:transport][:settings][:region]
        access_key_id = config[:transport][:settings][:access_key_id]
        secret_access_key = config[:transport][:settings][:secret_access_key]
        bucket = config[:transport][:settings][:bucket]

        # Regexes from dates in config
        regexes = Uphold::Files.get_date_regexes_from_config(config)

        # Top level folder path (without dates)
        general_path = Uphold::Files.get_general_path(config, '') # Ensure to pass empty string for no prefix

        # Objective of any transport is to get the paths of relevant backups given the general path directory
        # and the regexes to match with. Here, we first get all paths in the general directory
        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        paths = s3.list_objects(bucket: bucket, prefix: general_path).contents.select{|item| item.storage_class != 'GLACIER'}.collect(&:key)

        # Now, we filter the paths we got above with the regexes from dates
        Uphold::Files.get_paths_matching_regexes(paths, regexes, config[:engine][:settings][:extension])
      end
    end
  end
end
