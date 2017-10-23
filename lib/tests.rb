module Uphold
  class Tests
    include Logging
    include Command

    def initialize(ip_address:, port:, database:, tests:, user:)
      @ip_address = ip_address
      @port = port
      @database = database
      @tests = tests
      @user = user
    end

    def run
      logger.info 'Tests starting'
      t1 = Time.now

      outcomes = @tests.collect do |t|
        process = run_command("UPHOLD_IP=#{@ip_address} UPHOLD_PORT=#{@port} UPHOLD_DB=#{@database} UPHOLD_USER=#{@user} ruby /etc/uphold/tests/#{t}", 'ruby')
        if process.success?
          logger.info "Test #{t} finished successfully"
          true
        else
          logger.error "Test #{t} did NOT finish successfully"
          false
        end
      end

      t2 = Time.now
      delta = t2 - t1
      logger.info "Tests finished (#{format('%.2f', delta)}s)"
      !outcomes.include?(false)
    end
  end
end
