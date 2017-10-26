module Uphold
  module Transports
    class PostgresWalE < Transport
      include DateHelper
      include Command

      def initialize(params)
        super(params)
        @region = params[:region]
        @access_key_id = params[:access_key_id]
        @secret_access_key = params[:secret_access_key]
        @bucket = params[:bucket]

        # Set up Wal-E
        run_command('mkdir -p /etc/wal-e.d/env')
        run_command('chmod 777 /etc/wal-e.d')
        run_command('chmod 777 /etc/wal-e.d/env')
        run_command("echo \"#{@region}\" | tee /etc/wal-e.d/env/AWS_REGION")
        run_command("echo \"#{@access_key_id}\" | tee /etc/wal-e.d/env/AWS_ACCESS_KEY_ID")
        run_command("echo \"#{@secret_access_key}\" | tee /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY")
        run_command("echo \"#{@bucket}\" | tee /etc/wal-e.d/env/WALE_S3_PREFIX")
      end

      def fetch_backup
        # No path, return nil. The engine will figure out the appropriate backup from the date.
        nil
      end

      def self.get_backup_paths(config)
        region = config[:transport][:settings][:region]
        access_key_id = config[:transport][:settings][:access_key_id]
        secret_access_key = config[:transport][:settings][:secret_access_key]
        bucket = config[:transport][:settings][:snapshot_bucket]

        # Set up Wal-E
        run_command('mkdir -p /etc/wal-e.d/env')
        run_command('chmod 777 /etc/wal-e.d')
        run_command('chmod 777 /etc/wal-e.d/env')
        run_command("echo \"#{region}\" | tee /etc/wal-e.d/env/AWS_REGION")
        run_command("echo \"#{access_key_id}\" | tee /etc/wal-e.d/env/AWS_ACCESS_KEY_ID")
        run_command("echo \"#{secret_access_key}\" | tee /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY")
        run_command("echo \"#{bucket}\" | tee /etc/wal-e.d/env/WALE_S3_PREFIX")

        output = `envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-list`
        data = []
        output.lines.to_a[1..-1].each do |line|
          reg = /(base_\w{24}_\w{8})\s+(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}\w)\s+(\w{24})\s+(\d{8})/
          s = line.match(reg).captures
          d = {}
          d[:backup] = s[0]
          d[:date] = DateHelper.get_date_from_string(s[1], '%Y-%m-%dT%H%M%S')
          data << d
        end
        data
      end

      def self.get_logs
        # N/a
        fail 'Unsupported for this transport driver - Postgres Wal-E'
      end

      def self.get_log(filename)
        # N/a
        fail 'Unsupported for this transport driver - Postgres Wal-E'
      end

      def self.dump_logs
        # N/a
        fail 'Unsupported for this transport driver - Postgres Wal-E'
      end

      def self.touch_state_file(state)
        # N/a
        fail 'Unsupported for this transport driver - Postgres Wal-E'
      end

    end
  end
end
