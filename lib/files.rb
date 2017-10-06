module Uphold
  class Files
    include Logging
    include DateHelper
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
      # Latest date is the most specific.

      # Iterate through each date setting, with an array, then for every date setting you find the corresponding
      # date placement and then parse it back to DateTime.
      # For now, fuck zips and their internals.
      latest = nil
      dates = []
      path_local = path.clone
      config[:transport][:settings][:dates].each do |date|
        dates << DateHelper.get_date_from_string(path_local, date[:date_format])
      end

      dates.max

    end

  end
end