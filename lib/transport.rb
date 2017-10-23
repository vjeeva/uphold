module Uphold
  class Transport
    include Logging
    include Compression
    require 'date'

    attr_reader :tmpdir

    def initialize(params)
      @tmpdir = Dir.mktmpdir(nil, UPHOLD[:backup_tmp_path])
      @path = params[:path]
      @filename = params[:filename]
      @folder_within = params[:folder_within]
      @dates = params[:dates]
      @compressed = params[:compressed]

      @dates.each_with_index do |date_settings, index|
        date_format = date_settings[:date_format] || '%Y-%m-%d'
	      date_string = "{date" + index.to_s + "}"
        date = DateTime.strptime(ENV['TARGET_DATE'].to_s, '%s')
        @path.gsub!(date_string, date.strftime(date_format))
        @filename.gsub!(date_string, date.strftime(date_format))
      end

    end

    def fetch
      logger.info "Transport starting #{self.class}"
      logger.debug "Temporary directory '#{@tmpdir}'"

      t1 = Time.now
      path = fetch_backup
      t2 = Time.now
      delta = t2 - t1
      if path.nil?
        logger.fatal "Transport failed! (#{format('%.2f', delta)}s)"
        touch_state_file('bad_transport')
        exit 1
      else
        logger.info "Transport finished successfully (#{format('%.2f', delta)}s)"
        path
      end
    rescue => e
      touch_state_file('bad_transport')
      raise e
    end

    def fetch_backup
      fail "Your transport must implement the 'fetch' method"
    end

    def get_backup_paths
      fail "Your transport must implement the 'get_backup_paths' method"
    end

    def get_logs
      fail "Your transport must implement the 'get_logs' method"
    end

    def get_log
      fail "Your transport must implement the 'get_log' method"
    end

    def dump_logs
      fail "Your transport must implement the 'dump_logs' method"
    end

    def touch_state_file
      fail "Your transport must implement the 'touch_state_file' method"
    end
  end
end
