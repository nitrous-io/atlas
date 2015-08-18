require 'faye/websocket'
require 'eventmachine'

EM.run {
  EM.add_timer 5, proc {
    puts 'timed out'
    EM.stop_event_loop
  }

  ws = Faye::WebSocket::Client.new('ws://127.0.0.1:3000/')
  ws.on :open do |event|
    p [:open]
    ws.send('Hi')
  end

  ws.on :message do |event|
    p [:message, event.data]
    ws.close
    EM.stop_event_loop
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}