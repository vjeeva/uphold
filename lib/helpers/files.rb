module Uphold
  class Files
    # include Logging
    require 'find'

    def initialize(configs)
      @path = configs[0][:transport][:settings][:path] # CAN BE MULTIPLE!
      @extension = configs[0][:engine][:settings][:extension]
    end

    def backups
      if @path.include? '{date'
        index = @path.index('{date') # 0 based index
        general_path = '/mount' + @path[0..index-1]
        @backup_paths = []
        Find.find(general_path) do |path|
          @backup_paths << path.gsub!('/mount', '') if path.include? "#{@extension}"
        end
        @backup_paths
      end
    end

    def raw_test_logs
      raw_files.select { |file| File.extname(file) == '.log' }
    end

    def raw_state_files
      raw_files.select { |file| File.extname(file) == '' }
    end

    def raw_files
      Dir[File.join('/var/log/uphold', '*')].select { |log| File.basename(log) =~ /^[0-9]{10}/ }.map { |file| File.basename(file) }
    end

  end
end