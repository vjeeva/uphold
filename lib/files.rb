module Uphold
  class Files
    include Logging
    include DateHelper
    require 'find'

    def self.backups(config)
      # Fuck me this assumes uncompressed...
      config[:transport][:klass].get_backup_paths(config)
    end

    def self.raw_test_logs(config)
      raw_files(config).select { |file| File.extname(file) == '.log' }
    end

    def self.raw_state_files(config)
      raw_files(config).select { |file| File.extname(file) == '' }
    end

    def self.raw_files(config)
      # Need to switch between this, local or s3.
      if config.key?(:logs)
        config[:logs][:klass].get_logs(config)
      else
        Uphold::Transports::Local.get_logs(config)
      end
    end

    def self.extract_datetime_from_backup_path(config, path)
      # Latest date is the most specific.

      # Iterate through each date setting, with an array, then for every date setting you find the corresponding
      # date placement and then parse it back to DateTime.
      # For now, fuck zips and their internals.
      dates = []
      path_local = path.clone
      config[:transport][:settings][:dates].each do |date|
        dates << DateHelper.get_date_from_string(path_local, date[:date_format].to_s)
      end
      dates.max
    end

    def self.get_general_path(config, prefix)
      path = config[:transport][:settings][:path]
      general_path = path.clone
      if general_path.include? '{date'
        index = path.index('{date') # 0 based index
        general_path = prefix + path[0..index-1]
      end
      general_path
    end

    def self.get_date_regexes_from_config(config)
      regexes = []
      config[:transport][:settings][:dates].each do |date|
        # GOT IT: Need to stop removing {dateX} because there are outliers in the s3 bucket that don't conform. Need
        # better verification. Instead of this crap, sub in the dates with a regex!!!! THATS WHAT ITS FOR OMG LOL
        date_format = date[:date_format] || '%Y-%m-%d'
        regexes << DateHelper.regex_from_posix(date_format).to_s
      end
      regexes
    end

    def self.get_paths_matching_regexes(paths, regexes, extension)
      paths_local = paths.clone
      regexes.each do |regex|
        paths_selected = []
        paths_local.each do |path|
          paths_selected << path if path.match(regex) and path.include? extension
        end
        paths_local = paths_selected
      end
      paths_local
    end

  end
end