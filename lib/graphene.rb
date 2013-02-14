require './graphene/udp_broadcaster'
require './graphene/tcp_listener'

class Graphene
  attr :service_name, :broadcaster, :services, :service_aliases

  def initialize(service_name)
    @service_name = service_name
    @services = {}
    @service_aliases = {}

    @broadcaster = UDPBroadcaster.new
    @broadcaster.add_message_listener(self)

    %w{join query}.each do |type|
      @broadcaster.transmit({type: type, client_name: service_name})
    end

    #@tcp_listener = TCPListener.new
    #@tcp_listener.add_message_listener(self)
  end

  def udp_term()
    @broadcaster.transmit({type: 'quit'})
  end

  def new_tcp_message(from, message)
    puts "got client message: #{message}"

    parts = message.split(' ')

    if parts.size != 2 or parts.size != 4
      return "usage:\n\tget service-name\n\tset service-name host port"
    end

    case parts.first.downcase
    when 'get'
      return @service_aliases[parts.last] if @service_aliases[parts.last]
      return @services[parts.last] if @services[parts.last]
      return "0: no such service"
    when 'set'
      @service_aliases[parts[1]] = parts
    end

    return "bye!!"
  end

  def new_udp_message(message)
    case message["type"]
    when "join"
      puts "adding service #{message["name"]} at #{message["sender"][2]}:#{message["sender"][1]}"
      @services[message["client_id"]] = message["sender"]
    when "query"
      puts "sending services list:", @services
      @broadcaster.transmit({services: @services,
                             service_aliases: @service_aliases,
                             client_name: @service_name,
                             type: "inform"})
    when "inform"
      @services.merge!(message["services"])
      @services.keep_if {|k,v| k != @service_name }
      @services[message["client_id"]] << message["sender"]
      @services[message["client_id"]].uniq!

      @service_aliases.merge!(message["service_aliases"])
      @service_aliases[message["client_name"]] = message["client_id"]
    when "quit"
      puts "removing service #{message["name"]}"
      @services.delete message["client_id"]
      @service_aliases.delete message["name"]
    end

    puts "services:"
    p @services

    puts "service aliases:"
    p @service_aliases
  end
end
