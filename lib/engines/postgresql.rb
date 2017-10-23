module Uphold
  module Engines
    class Postgresql < Engine

      def initialize(params)
        super(params)
        @docker_image ||= 'postgres'
        @docker_tag ||= '9.5'
        @extension ||= '.sql'
        @restore_type = params[:restore_type] || 'psql'
        @port ||= 5432
        @username = params[:username] || 'postgres'
        @docker_env ||= ["POSTGRES_USER=#{@username}", "POSTGRES_DB=#{@database}"]
        @sql_file = params[:sql_file] ||  'PostgreSQL.sql'
        @dates = params[:dates]
        @cores = params[:cores] || 4
        @command_timeout = params[:command_timeout] || 3600

        @dates.each_with_index do |date_settings, index|
	        date_format = date_settings[:date_format] || '%Y-%m-%d'
	        date_string = '{date' + index.to_s + '}'
          date = DateTime.strptime(ENV['TARGET_DATE'].to_s, '%s')
          @sql_file.gsub!(date_string, date.strftime(date_format))
        end
        params[:extension] = @extension
      end

      def load_backup(path, container)
        path = File.join(path, @sql_file)
        if @restore_type.include?("psql")
          res = container.exec(["bash", "-c", "psql --no-password --set ON_ERROR_STOP=on --username=#{@username} --dbname=#{@database} #{path}"], wait: @command_timeout)
          result(res)
        elsif @restore_type.include?("pg_restore")
          res = container.exec(["bash", "-c", "pg_restore -j #{@cores} --verbose --no-password --exit-on-error --username=#{@username} --dbname=#{@database} #{path}"], wait: @command_timeout)
          result(res)
        else
          raise 'Restore Type parameter in Postgresql Config is invalid.'
        end
      end
    end
  end
end