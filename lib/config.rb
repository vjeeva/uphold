module Uphold
  class Config
    require 'yaml'
    include Logging
    PREFIX = '/etc/uphold'

    attr_reader :yaml

    def initialize(config)
      fail unless config
      yaml = YAML.load_file(File.join(PREFIX, 'conf.d', config))
      yaml.merge!(file: File.basename(config, '.yml'))
      @yaml = Config.deep_convert(yaml)
      fail unless valid?
      logger.debug "Loaded config '#{@yaml[:name]}' from '#{config}'"
      @yaml[:tests] ||= []
      @yaml = supplement
    end

    def valid?
      valid = true
      valid = false unless Config.engines.any? { |e| e[:name] == @yaml[:engine][:type] }
      valid = false unless Config.transports.any? { |e| e[:name] == @yaml[:transport][:type] }
      valid
    end

    def supplement
      @yaml[:engine][:klass] = Config.engines.find { |e| e[:name] == @yaml[:engine][:type] }[:klass]
      @yaml[:transport][:klass] = Config.transports.find { |e| e[:name] == @yaml[:transport][:type] }[:klass]
      @yaml
    end

    def self.load_configs
      Dir[File.join(PREFIX, 'conf.d', '*.yml')].sort.map do |file|
        new(File.basename(file)).yaml
      end
    end

    def self.load_global
      yaml = YAML.load_file(File.join(PREFIX, 'uphold.yml'))
      yaml = deep_convert(yaml)
      yaml[:log_level] ||= 'DEBUG'
      yaml[:docker_url] ||= 'unix:///var/run/docker.sock'
      yaml[:docker_container] ||= 'vjeeva/uphold-tester'
      yaml[:docker_tag] ||= 'latest'
      yaml[:docker_mounts] ||= []
      yaml[:config_path] ||= '/etc/uphold'
      yaml[:docker_log_path] ||= '/var/log/uphold'
      yaml[:ui_datetime] ||= '%F %T %Z'
      yaml
    end

    # TODO: UPDATE AS NEEDED
    def self.load_message_queues_config
      yaml = YAML.load_file(File.join(PREFIX, 'message_queue.yml'))
      yaml = deep_convert(yaml)
      yaml[:type] ||= 'sqs'
      if Config.message_queues.any? { |e| e[:name] == yaml[:type] }
        yaml[:klass] = Config.message_queues.find { |e| e[:name] == yaml[:type] }[:klass]
      end
      yaml
    end

    def self.load_engines
      [Dir["#{ROOT}/lib/engines/*.rb"], Dir[File.join(PREFIX, 'engines', '*.rb')]].flatten.uniq.sort.each do |file|
        require file
        basename = File.basename(file, '.rb')
        add_engine name: basename, klass: Object.const_get("Uphold::Engines::#{File.basename(file, '.rb').capitalize}")
      end
    end

    def self.engines
      @engines ||= []
    end

    def self.add_engine(engine)
      list = engines
      list << engine
      logger.debug "Loaded engine #{engine[:klass]}"
      list.uniq! { |e| e[:name] }
    end

    def self.load_transports
      [Dir["#{ROOT}/lib/transports/*.rb"], Dir[File.join(PREFIX, 'transports', '*.rb')]].flatten.uniq.sort.each do |file|
        require file
        basename = File.basename(file, '.rb')
        add_transport name: basename, klass: Object.const_get("Uphold::Transports::#{File.basename(file, '.rb').capitalize}")
      end
    end

    def self.add_transport(transport)
      list = transports
      list << transport
      logger.debug "Loaded transport #{transport[:klass]}"
      list.uniq! { |e| e[:name] }
    end

    def self.transports
      @transports ||= []
    end

    def self.load_message_queues
      [Dir["#{ROOT}/lib/message_queues/*.rb"], Dir[File.join(PREFIX, 'message_queues', '*.rb')]].flatten.uniq.sort.each do |file|
        require file
        basename = File.basename(file, '.rb')
        add_message_queue name: basename, klass: Object.const_get("Uphold::MessageQueues::#{File.basename(file, '.rb').capitalize}")
      end
    end

    def self.message_queues
      @message_queues ||= []
    end

    def self.add_message_queue(message_queue)
      list = message_queues
      list << message_queue
      logger.debug "Loaded message queue #{message_queue[:klass]}"
      list.uniq! { |e| e[:name] }
    end

    private

    def self.deep_convert(element)
      return element.collect { |e| deep_convert(e) } if element.is_a?(Array)
      return element.inject({}) { |sh,(k,v)| sh[k.to_sym] = deep_convert(v); sh } if element.is_a?(Hash)
      element
    end
  end
end
