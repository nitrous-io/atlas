require 'spec_helper'

describe 'Preview HTTP Proxy' do
  it 'sends a request through proxy' do
    response = RestClient::Request.execute(method: :get, url: 'http://server0.nitrousapp.com', timeout: 10)
    expect(response.code).to eq(200)
  end

  it 'returns 502 with error page when the port is not open' do
    expect do
      RestClient::Request.execute(method: :get, url: 'http://server0.nitrousapp.com:3001', timeout: 10)
    end.to raise_error do |error|
      expect(error).to be_a RestClient::BadGateway
      expect(error.response).to include 'are you sure there is a server running?'
    end
  end

  it 'returns 502 with error page when the port is open and server is not up' do
    expect do
      RestClient::Request.execute(method: :get, url: 'http://server0.nitrousapp.com:4000', timeout: 10)
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
    EM.run {
      EM.add_timer 5, proc { EM.stop_event_loop }

      ws = Faye::WebSocket::Client.new('ws://server1.nitrousapp.com/')
      ws.on :open do
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
  end
end