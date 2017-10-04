module Uphold
  module Engines
    class Postgresql < Engine

      def initialize(params)
        super(params)
        @docker_image ||= 'postgres'
        @docker_tag ||= '9.5'
        @file_type ||= 'sql'
        @port ||= 5432
        @username ||= 'postgres'
        @docker_env ||= ["POSTGRES_USER=#{@username}", "POSTGRES_DB=#{@database}"]
        @sql_file = params[:sql_file] ||  'PostgreSQL.sql'
        @dates = params[:dates]

        @dates.each_with_index do |date_settings, index|
	  date_format = date_settings[:date_format] || '%Y-%m-%d'
	  date_offset = date_settings[:date_offset] || 0
	  date_string = '{date' + index.to_s + '}'
	  @sql_file.gsub!(date_string, (Date.today - date_offset).strftime(date_format))
	end
      end

      def load_backup(path)
        Dir.chdir(path) do
          if @file_type.include?("sql")
            run_command("psql --no-password --set ON_ERROR_STOP=on --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")
          elsif @file_type.include?("dump")
             run_command("pg_restore --no-password --set ON_ERROR_STOP=on --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")
          else
            raise 'File Type parameter in Postgresql Driver is invalid.'
          end
        end
      end
    end
  end
end
