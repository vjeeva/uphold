module Uphold
  module Engines
    class Postgresql < Engine

      def initialize(params)
        super(params)
        @docker_image ||= 'postgres'
        @docker_tag ||= '9.5.0'
        @docker_env ||= ["POSTGRES_USER=#{@database}", "POSTGRES_DB=#{@database}"]
        @file_type ||= 'sql'
        @port ||= 5432
        @username ||= 'postgres'
        @sql_file = params[:sql_file] ||  'PostgreSQL.sql'
      end

      def load_backup(path)
        Dir.chdir(path) do
          if @file_type.contains("sql")
            run_command("psql --no-password --set ON_ERROR_STOP=on --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")
          elsif @file_type.contains("dump")
             run_command("pg_restore --no-password --set ON_ERROR_STOP=on --username=#{@username} --host=#{container_ip_address} --port=#{@port} --dbname=#{@database} < #{@sql_file}")i
          else
            raise 'File Type parameter in Postgresql Driver is invalid.'
          end
        end
      end
    end
  end
end
