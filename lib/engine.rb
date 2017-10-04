module Uphold
  class Engine
    include Logging
    include Command
    include Sockets

    attr_reader :port, :database

    def initialize(params)
      @database = params[:database]
      @docker_image = params[:docker_image]
      @docker_tag = params[:docker_tag]
      @docker_env = params[:docker_env]
      @timeout = params[:timeout] || 10
      @container = nil
      @port = nil
    end

    def load(path:)
      logger.info "Engine starting #{self.class}"
      t1 = Time.now
      process = load_backup(path)
      t2 = Time.now
      delta = t2 - t1
      if process.success?
        logger.info "Engine finished successfully (#{format('%.2f', delta)}s)"
        true
      else
        logger.error "Engine failed! (#{format('%.2f', delta)}s)"
        false
      end
    rescue => e
      touch_state_file('bad_engine')
      raise e
    end

    def load_backup
      fail "Your engine must implement the 'load_backup' method"
    end

    def start_container
      if Docker::Image.exist?("#{@docker_image}:#{@docker_tag}")
        logger.debug "Docker image '#{@docker_image}' with tag '#{@docker_tag}' available"
        Docker::Image.get("#{@docker_image}:#{@docker_tag}")
      else
        logger.debug "Docker image '#{@docker_image}' with tag '#{@docker_tag}' does not exist locally, fetching"
        Docker::Image.create('fromImage' => @docker_image, 'tag' => @docker_tag)
      end

      logger.debug @docker_image + ":" + @docker_tag
      @container = Docker::Container.create(
        'Image' => "#{@docker_image}:#{@docker_tag}",
        'Env' => @docker_env
      )
      @container.start
      logger.debug "Docker container '#{container_name}' starting"
      wait_for_container_to_be_ready
    rescue => e
      touch_state_file('bad_engine')
      logger.info 'Backup is BAD'
      raise e
    end

    def wait_for_container_to_be_ready
      logger.debug "Waiting for Docker container '#{container_name}' to be ready"
      tcp_port_open?(container_name, container_ip_address, port, @timeout)
    end

    def container_ip_address
      @container.json['NetworkSettings']['IPAddress']
    end

    def container_id
      @container.id[0..11]
    end

    def container_name
      File.basename @container.json['Name']
    end

    def stop_container
      logger.debug "Docker container '#{container_name}' stopping"
      @container.stop
      @container.delete
    end

  end
end
