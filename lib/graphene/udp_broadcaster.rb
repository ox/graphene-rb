require 'socket'
require 'thread'
require 'ipaddr'
require 'uuid'
require 'json'

class UDPBroadcaster
  MULTICAST_ADDR = "224.3.5.13"
  BIND_ADDR = "0.0.0.0"
  PORT = "3513"

  def initialize
    @client_id = UUID.generate
    @listeners = []
  end

  def add_message_listener(listener)
    listen unless listening?
    @listeners << listener
  end

  def transmit(content)
    message = content.merge({client_id: @client_id}).to_json
    socket.send(message, 0, MULTICAST_ADDR, PORT)
    puts "sent transmission"
    message.to_json
  end

  private

  def listen
    puts "UDP server listening..."
    socket.bind(BIND_ADDR, PORT)

    Thread.new do
      Signal.trap "SIGINT" do
        @listeners.each {|listener| listener.udp_term() }
        socket.close
        exit
      end

      loop do
        attributes, sender_inet_addr = socket.recvfrom(1024)
        message = JSON.parse(attributes).merge({"sender" => sender_inet_addr})

        unless message["client_id"] == @client_id
          @listeners.each { |listener| listener.new_udp_message(message) }
        end
      end
    end

    @listening = true
  end

  def listening?
    @listening == true
  end

  def socket
    @socket ||= UDPSocket.open.tap do |socket|
      socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, bind_address)
      socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 1)
      socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
    end
  end

  def bind_address
    IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton
  end
end
