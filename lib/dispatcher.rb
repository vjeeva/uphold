module Uphold
  class Dispatcher
    include Logging

    def initialize(config)
      @queue = config[:klass]
      @config = config
    end

    def start
      queue = @queue.new(@config)

      # Listen


    end

    def start_docker_container(slug, timestamp)
      if Docker::Image.exist?("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
        Docker::Image.get("#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}")
      else
        Docker::Image.create('fromImage' => UPHOLD[:docker_container], 'tag' => UPHOLD[:docker_tag])
      end

      volumes = {}
      UPHOLD[:docker_mounts].flatten.each { |m| volumes[m] = { "#{m}" => 'ro' } }

      # this is a hack for when you're working in development on osx
      volumes[UPHOLD[:config_path]] = { '/etc/uphold' => 'ro' }
      volumes[UPHOLD[:docker_log_path]] = { '/var/log/uphold' => 'rw' }

      # Unix sockets when mounted can't have the protocol at the start
      if UPHOLD[:docker_url].include?('unix://')
        without_protocol = UPHOLD[:docker_url].split('unix://')[1]
        volumes[without_protocol] = { "#{without_protocol}" => 'rw' }
      end

      @container = Docker::Container.create(
          'Image' => "#{UPHOLD[:docker_container]}:#{UPHOLD[:docker_tag]}",
          'Cmd' => [slug + '.yml'],
          'Volumes' => volumes,
          'Env' => ["UPHOLD_LOG_FILENAME=#{timestamp}_#{slug}", "TARGET_DATE=#{timestamp}"]
      )

      @container.start('Binds' => volumes.map { |v, h| "#{v}:#{h.keys.first}" })
    end

  end
end