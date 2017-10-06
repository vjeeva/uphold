module Uphold
  class Files
    # include Logging
    require 'find'

    def backups(config)
      # Fuck me this assumes uncompressed...
      path = config[:transport][:settings][:path]
      if path.include? '{date'
        index = path.index('{date') # 0 based index
        general_path = '/mount' + path[0..index-1]
        backup_paths = []
        Find.find(general_path) do |path|
          backup_paths << path.gsub!('/mount', '') if path.include? "#{config[:engine][:settings][:extension]}"
        end
        backup_paths
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

    def extract_datetime_from_backup_path(config, path)
      # Most specific time in unix time would be the highest number!

      # Iterate through each date setting, with an array, then for every date setting you find the corresponding
      # date placement and then parse it back to DateTime.
      # For now, fuck zips and their internals.
      dates = []
      path_local = path
      config[:transport][:settings][:dates].each do |date|
        DateTime.strptime(path, date[:date_format])
      end

    end

  end
end