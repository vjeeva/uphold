module Uphold
  class Engine
    include Logging
    include Command
    include Sockets
    Result = Struct.new(:success?, :stdout, :stderr)

    attr_reader :port, :database

    def initialize(params)
      @database = params[:database]
      @docker_image = params[:docker_image]
      @docker_tag = params[:docker_tag]
      @docker_env = params[:docker_env]
      @timeout = params[:timeout] || 10
      @container = nil
      @port = nil
      @extension = params[:extension]
      @username ||= params[:username]
    end

    def load(path:, container:)
      logger.info "Engine starting #{self.class}"
      t1 = Time.now
      process = load_backup(path, container)
      t2 = Time.now
      delta = t2 - t1
      if process.success?
        logger.info "Engine finished successfully (#{format('%.2f', delta)}s)"
        logger.debug process.stdout
        logger.error process.stderr
        true
      else
        logger.error "Engine failed! (#{format('%.2f', delta)}s)"
        logger.debug process.stdout
        logger.error process.stderr
        false
      end
    rescue => e
      touch_state_file('bad_engine')
      raise e
    end

    def load_backup
      fail "Your engine must implement the 'load_backup' method"
    end

    def start_container(backup_dir)
      if Docker::Image.exist?("#{@docker_image}:#{@docker_tag}")
        logger.debug "Docker image '#{@docker_image}' with tag '#{@docker_tag}' available"
        Docker::Image.get("#{@docker_image}:#{@docker_tag}")
      else
        logger.debug "Docker image '#{@docker_image}' with tag '#{@docker_tag}' does not exist locally, fetching"
        Docker::Image.create('fromImage' => @docker_image, 'tag' => @docker_tag)
      end

      volumes = {}
      UPHOLD[:docker_mounts].flatten.each { |m| volumes[m] = { "#{m}" => 'ro' } }
      if not backup_dir.nil?
        volumes[backup_dir] = { "#{backup_dir}" => 'ro'}
      end

      @container = Docker::Container.create(
        'Image' => "#{@docker_image}:#{@docker_tag}",
        'Env' => @docker_env,
        'Volumes' => volumes
      )
      @container.start('Binds' => volumes.map { |v, h| "#{v}:#{h.keys.first}" })
      logger.debug "Docker container '#{container_name}' starting"
      wait_for_container_to_be_ready
    rescue => e
      touch_state_file('bad_engine')
      logger.info 'Backup is BAD'
      raise e
    end

    def get_container
      @container
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

    def user
      @username
    end

    def stop_container
      logger.debug "Docker container '#{container_name}' stopping"
      @container.stop
      # @container.delete
    end

    def get_backups
      if @files == nil
        raise error("Engine did not initialize files!")
        exit 1
      end
      @files.get_backups
    end

    def result(res)
      if res[2] == 0
        Result.new(true, res[0], res[1])
      else
        Result.new(false, res[0], res[1])
      end
    end

  end
end
