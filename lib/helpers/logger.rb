module Uphold
  require 'logger'

  module Logging
    # Well shit... so basically the local path can change fine using UPHOLD config, but what about s3? Can't just tee out.
    # s3fs wasn't an option either, took too long. I need to dump logs when done? Sucks because I can check live local but
    # if i force all do to that, then no live eber. Or make a bit complicated to get some live. Weeeeelllll to be fair I
    # docker log myself anyways... Give this some more though.
    class << self
      def logger
        loc = UPHOLD[:logs][:settings][:path] || '/var/log/uphold'
        @logger ||= Logger.new("| tee #{loc}/#{ENV['UPHOLD_LOG_FILENAME'].nil? ? 'uphold' : ENV['UPHOLD_LOG_FILENAME']}.log")
      end

      def logger=(logger)
        @logger = logger
      end
    end

    # Addition
    def self.included(base)
      class << base
        def logger
          Logging.logger
        end
      end
    end

    def self.get_log_path

    end

    def logger
      Logging.logger
    end

    def touch_state_file(state)
      UPHOLD[:logs][:klass].touch_state_file(state)
    end
  end
end
