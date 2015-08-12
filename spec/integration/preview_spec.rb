require 'spec_helper'

describe 'Preview Proxy' do
  it 'sends a request through proxy' do
    response = RestClient::Request.execute(method: :get, url: 'http://server0.nitrousapp.com', timeout: 10)
    expect(response.code).to eq(200)
  end
end