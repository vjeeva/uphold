module Uphold
  class Transport
    include Logging
    include Compression

    attr_reader :tmpdir

    def initialize(params)
      @tmpdir = Dir.mktmpdir('uphold')
      @path = params[:path]
      @filename = params[:filename]
      @folder_within = params[:folder_within]
      @dates = params[:dates]
      @compressed = params[:compressed]

      @dates.each_with_index do |date_settings, index|
        date_format = date_settings[:date_format] || '%Y-%m-%d'
        date_offset = date_settings[:date_offset] || 0
	date_string = "{date" + index.to_s + "}"
        @path.gsub!(date_string, (Date.today - date_offset).strftime(date_format))
        @filename.gsub!(date_string, (Date.today - date_offset).strftime(date_format))
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
  end
end
