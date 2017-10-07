module Uphold
  module Engines
    class Postgresql < Engine

      def initialize(params)
        super(params)
        @docker_image ||= 'postgres'
        @docker_tag ||= '9.5'
        @extension ||= '.sql'
        @port ||= 5432
        @username = params[:username] || 'postgres'
        @docker_env ||= ["POSTGRES_USER=#{@username}", "POSTGRES_DB=#{@database}"]
        @sql_file = params[:sql_file] ||  'PostgreSQL.sql'
        @dates = params[:dates]

        @dates.each_with_index do |date_settings, index|
	        date_format = date_settings[:date_format] || '%Y-%m-%d'
	        date_string = '{date' + index.to_s + '}'
          date = DateTime.strptime(ENV['TARGET_DATE'].to_s, '%s')
          @sql_file.gsub!(date_string, date.strftime(date_format))
        end
        params[:extension] = @extension
      end

      def load_backup(path)
        Dir.chdir(path) do
          if @extension.include?(".sql")
            run_command("psql --no-password --exit-on-error --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")
          elsif @extension.include?(".pg_dump")
             run_command("pg_restore --no-password --exit-on-error --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")
          else
            raise 'File Type parameter in Postgresql Driver is invalid.'
          end
        end
      end
    end
  end
end
