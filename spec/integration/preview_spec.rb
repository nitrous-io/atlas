require 'spec_helper'

describe 'Preview HTTP Proxy' do
  it 'sends a request through proxy' do
    response = RestClient::Request.execute(method: :get, url: 'http://server0.nitrousapp.com', timeout: 10)
    expect(response.code).to eq(200)
  end

  # server1's freighterd port is 65334 but freightered is running on port 65333
  it 'returns 502 with error page when freighterd port is not open' do
    expect do
      RestClient::Request.execute(method: :get, url: 'http://server1.nitrousapp.com:3001', timeout: 10)
    end.to raise_error do |error|
      expect(error).to be_a RestClient::BadGateway
      expect(error.response).to include 'are you sure there is a server running?'
    end
  end

  it 'returns 404 with error page when host does not exist' do
    expect do
      RestClient::Request.execute(method: :get, url: 'http://no_server.nitrousapp.com', timeout: 10)
    end.to raise_error do |error|
      expect(error).to be_a RestClient::NotFound
    end
  end
end

describe 'Preview Websocket Proxy' do
  it 'sends a request through proxy' do
    success = false
    nitrous_proxy_container_slug = nitrous_proxy_container_port = ''

    EM.run {
      EM.add_timer 5, proc { EM.stop_event_loop }

      ws = Faye::WebSocket::Client.new('ws://server2.nitrousapp.com:3001')
      ws.on :open do
        nitrous_proxy_container_slug = ws.headers['x-nitrous-proxy-container-slug']
        nitrous_proxy_container_port = ws.headers['x-nitrous-proxy-container-port']
        ws.send('Hi')
      end

      ws.on :message do
        ws.close
        success = true
        EM.stop_event_loop
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        EM.stop_event_loop
      end
    }

    expect(success).to eq(true)
    expect(nitrous_proxy_container_slug).to eq('server2')
    expect(nitrous_proxy_container_port).to eq('3001')
  end
end
