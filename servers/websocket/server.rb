require 'faye/websocket'
require 'eventmachine'
require 'rack'
require 'thin'

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :open do
      p [:open]
    end

    ws.on :message do |event|
      p [:message, event.data]
      ws.send(event.data)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    ws.rack_response
  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Hello']]
  end
end

Faye::WebSocket.load_adapter('thin')
thin = Rack::Handler.get('thin')
thin.run(App, Host: '0.0.0.0', Port: 65333)
