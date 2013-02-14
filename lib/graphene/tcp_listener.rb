require 'socket'

class TCPListener
  BIND_ADDR = "0.0.0.0"
  PORT = "3515"

  attr :server, :listener, :listening

  def initialize
    @listener = nil
    @server = TCPServer.new BIND_ADDR, PORT
  end

  def add_message_listener(listener)
    listen unless @listening
    @listener = listener
  end

  def listen
    puts "TCP server listening..."

    Thread.start do
      loop do
        Thread.start(@server.accept) do |client|
          puts "#{client.addr[2]} connected"
          client.puts @listener.new_tcp_message(client.addr[2], client.gets)
          client.close
        end
      end
    end

    @listening = true
  end
end
