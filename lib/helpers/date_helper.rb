module Uphold
  module DateHelper

    def posix_date_regex_dict
      dict = Hash.new
      #  %%     a literal %
      dict['%%'] = /(%)/
      #  %a     locale's abbreviated weekday name (e.g., Sun)
      dict['%a'] = /(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/
      #  %A     locale's full weekday name (e.g., Sunday)
      dict['%A'] = /(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)/
      #  %b     locale's abbreviated month name (e.g., Jan)
      dict['%b'] = /(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/
      #  %B     locale's full month name (e.g., January)
      dict['%B'] = /(January|February|March|April|May|June|July|August|September|October|November|December)/
      #  %C     century; like %Y, except omit last two digits (e.g., 20)
      dict['%C'] = /([2-9][0-9])/
      #  %d     day of month (e.g., 01)
      dict['%d'] = /(0[1-9]|[1-2][0-9]|3[0-1])/
      #  %c     locale's date and time (e.g., Thu Mar  3 23:05:25 2005)
      dict['%c'] = Regexp.new('(' + dict['%a'].to_s + ' ' + dict['%b'].to_s + '\s+' + dict['%d'].to_s + ' ' +
                                  dict['%T'].to_s + ' ' + dict['%Y'].to_s + ')')
      #  %D     date; same as %m/%d/%y
      dict['%D'] = Regexp.new('(' + dict['%m'].to_s + '/' + dict['%d'].to_s +
                                  '/' + dict['%y'].to_s + ')')
      #  %F     full date; same as %Y-%m-%d
      dict['%F'] = Regexp.new('(' + dict['%Y'].to_s + '-' + dict['%m'].to_s +
                                  '-' + dict['%d'].to_s + ')')
      #  %g     last two digits of year of ISO week number (see %G)
      dict['%g'] = dict['%y']
      #  %G     year of ISO week number (see %V); normally useful only with %V
      dict['%G'] = dict['%Y']
      #  %h     same as %b
      dict['%h'] = dict['%b']
      #  %H     hour (00..23)
      dict['%H'] = /([0-1][0-9]|2[0-3])/
      #  %I     hour (01..12)
      dict['%I'] = /(0[1-9]|1[0-2])/
      #  %j     day of year (001..366)
      dict['%j'] = /([0-2][0-9][0-9]|3[0-5][0-9]|36[0-6])/
      #  %m     month (01..12)
      dict['%m'] = dict['%I']
      #  %M     minute (00..59)
      dict['%M'] = /([0-5][0-9])/
      #  %n     a newline
      dict['%n'] = /(\n)/
      #  %N     nanoseconds (000000000..999999999)
      dict['%N'] = /(\d{9})/
      #  %p     locale's equivalent of either AM or PM; blank if not known (* instead of | blank) bc what if concat)
      dict['%p'] = /(((A|P)M)*)/
      #  %P     like %p, but lower case
      dict['%P'] = /(((a|p)m)*)/
      #  %q     quarter of year (1..4)
      dict['%q'] = /([1-4])/
      #  %r     locale's 12-hour clock time (e.g., 11:11:04 PM)
      dict['%r'] = Regexp.new('(' + dict['%I'].to_s + ':' + dict['%M'].to_s +
                                  ':' + dict['%S'].to_s + ' ' + dict['%p'].to_s + ')')
      #  %R     24-hour hour and minute; same as %H:%M
      dict['%R'] = Regexp.new('(' + dict['%H'].to_s + ':' + dict['%M'].to_s + ')')
      #  %s     seconds since 1970-01-01 00:00:00 UTC
      dict['%s'] = /(\d{10})/
      #  %S     second (00..60)
      dict['%S'] = /([0-5][0-9]|60)/
      #  %t     a tab
      dict['%t'] = /(\t)/
      #  %T     time; same as %H:%M:%S
      dict['%T'] = Regexp.new('(' + dict['%H'].to_s + ':' + dict['%M'].to_s +
                                  ':' + dict['%S'].to_s + ')')
      #  %u     day of week (1..7); 1 is Monday
      dict['%u'] = /([1-7])/
      #  %U     week number of year, with Sunday as first day of week (00..53)
      dict['%U'] = /([0-4][0-9]|5[0-3])/
      #  %V     ISO week number, with Monday as first day of week (01..53)
      dict['%V'] = /(0[1-9]|[1-4][0-9]|5[0-3])/
      #  %w     day of week (0..6); 0 is Sunday
      dict['%w'] = /([0-6])/
      #  %W     week number of year, with Monday as first day of week (00..53)
      dict['%W'] = dict['%U']
      #  %x     locale's date representation (e.g., 12/31/99)
      dict['%x'] = Regexp.new('(' + dict['%m'].to_s + '/' + dict['%d'].to_s + '/' + dict['%Y'].to_s + ')')
      #  %X     locale's time representation (e.g., 23:13:48)
      dict['%X'] = dict['%T']
      #  %y     last two digits of year (00..99)
      dict['%y'] = /(\d{2})/
      #  %Y     year
      dict['%Y'] = /(\d{4})/
      #  %z     +hhmm numeric time zone (e.g., -0400)
      dict['%z'] = /((-|\+)\d{4})/ # Lazy
      #  %:z    +hh:mm numeric time zone (e.g., -04:00)
      dict['%:z'] = /((-|\+)\d{2}:\d{2})/ # Lazy
      #  %::z   +hh:mm:ss numeric time zone (e.g., -04:00:00)
      dict['%::z'] = /((-|\+)\d{2}:\d{2}:\d{2})/ # Lazy
      #  %:::z  numeric time zone with : to necessary precision (e.g., -04,
      #         +05:30)
      dict['%:::z'] = /(((-|\+)\d{2}:\d{2})|((-|\+)\d{2}))/
      #  %Z     alphabetic time zone abbreviation (e.g., EDT)
      dict['%Z'] = /(\w{3})/
      #  %k     hour, space padded ( 0..23); same as %_H
      dict['%k'] = Regexp.new('(' + '\s+' + dict['%H'].to_s + ')')
      #  %l     hour, space padded ( 1..12); same as %_I
      dict['%l'] = Regexp.new('(' + '\s+' + dict['%I'].to_s + ')')
      #  %e     day of month, space padded; same as %_d
      dict['%e'] = Regexp.new('(' + '\s+' + dict['%d'].to_s + ')')

      # Haven't covered optional flags yet
      #  By default, date pads numeric fields with zeroes.  The following
      #  optional flags may follow '%':
      #
      #  -      (hyphen) do not pad the field
      #
      #  _      (underscore) pad with spaces
      #
      #  0      (zero) pad with zeros
      #
      #  ^      use upper case if possible
      #
      #  #      use opposite case if possible

      dict
    end

    def regex_from_posix(posix)

      regex = nil

      while posix.length > 0
        if posix[0] == '%'
          index = 999999
          early_key = nil
          posix_date_regex_dict.keys.each do |key|
            test_index = posix.index Regexp.new(key)
            if test_index != nil and test_index < index
              index = test_index
              early_key = key
            end
          end
          regex = Regexp.new(regex.to_s + posix_date_regex_dict[early_key].to_s)
          posix.sub!(early_key.to_s, '')
        else
          regex = Regexp.new(regex.to_s + posix[0])
          posix.sub!(posix[0], '')
        end
      end
      regex
    end

    def get_date_from_string(string, posix)
      regex = regex_from_posix(posix)
      date = DateTime.strptime(string.match(regex).to_s, posix)
      string.sub!(regex, '') # Consume it
      date
    end

  end
end