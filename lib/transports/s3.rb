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
        regexes = Uphold::Files.get_regexes_from_config(config)

        # Top level folder path (without dates)
        general_path = Uphold::Files.get_general_path(config, '') # Ensure to pass empty string for no prefix

        # Objective of any transport is to get the paths of relevant backups given the general path directory
        # and the regexes to match with. Here, we first get all paths in the general directory
        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        paths = s3.list_objects(bucket: bucket, prefix: general_path).contents.select{|item| item.storage_class != 'GLACIER'}.collect(&:key)

        # Now, we filter the paths we got above with the regexes from dates
        paths = Uphold::Files.get_paths_matching_regexes(paths, regexes, config[:engine][:settings][:extension])
        array = []

        paths.each do |path|
          d = {}
          d[:backup] = path
          d[:date] = Files.extract_datetime_from_backup_path(config, path)
          array << d
        end
        array
      end

      def self.get_logs
        region = UPHOLD[:logs][:settings][:region]
        access_key_id = UPHOLD[:logs][:settings][:access_key_id]
        secret_access_key = UPHOLD[:logs][:settings][:secret_access_key]
        bucket = UPHOLD[:logs][:settings][:bucket]
        path = UPHOLD[:logs][:settings][:path]

        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        s3.list_objects(bucket: bucket, prefix: path).contents.select{|item| item.storage_class != 'GLACIER'}.collect(&:key).select { |log| File.basename(log) =~ /^[0-9]{10}/ }.map { |file| File.basename(file) }
      end

      def self.get_log(filename)
        region = UPHOLD[:logs][:settings][:region]
        access_key_id = UPHOLD[:logs][:settings][:access_key_id]
        secret_access_key = UPHOLD[:logs][:settings][:secret_access_key]
        bucket = UPHOLD[:logs][:settings][:bucket]

        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        tmpdir = Dir.mktmpdir('log')
        dir = File.join(tmpdir, filename)
        File.open(dir, 'wb') do |file|
          resp = s3.get_object({ bucket: bucket, key: filename }, target: file)
        end
        dir
      end

      def self.dump_logs
        region = UPHOLD[:logs][:settings][:region]
        access_key_id = UPHOLD[:logs][:settings][:access_key_id]
        secret_access_key = UPHOLD[:logs][:settings][:secret_access_key]
        bucket = UPHOLD[:logs][:settings][:bucket]

        # IF the logs dump to s3, then logger will default to /var/log/uphold on the local machine/container, so we copy that file to S3.

        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        File.open("/var/log/uphold/#{ENV['UPHOLD_LOG_FILENAME']}.log", 'rb') do |file|
          s3.put_object(bucket: bucket, key: "#{ENV['UPHOLD_LOG_FILENAME']}.log", body: file)
        end
      end

      def self.touch_state_file(state)
        region = UPHOLD[:logs][:settings][:region]
        access_key_id = UPHOLD[:logs][:settings][:access_key_id]
        secret_access_key = UPHOLD[:logs][:settings][:secret_access_key]
        bucket = UPHOLD[:logs][:settings][:bucket]

        loc = UPHOLD[:logs][:settings][:path] || '/var/log/uphold'
        s3 = Aws::S3::Client.new(region: region, access_key_id: access_key_id, secret_access_key: secret_access_key)
        FileUtils.touch(File.join(loc, ENV['UPHOLD_LOG_FILENAME'] + '_' + state)) unless ENV['UPHOLD_LOG_FILENAME'].nil?
        File.open("/var/log/uphold/#{ENV['UPHOLD_LOG_FILENAME']}_#{state}", 'rb') do |file|
          s3.put_object(bucket: bucket, key: "#{ENV['UPHOLD_LOG_FILENAME']}_#{state}", body: file)
        end
      end

    end
  end
end
