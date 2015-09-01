package.path = './proxy/nginx/lualib/?.lua;' .. package.path

describe(".get_slug_from_uri", function()
  it("returns subdomain", function()
    local common = require 'common'
    assert.are.equal(common.get_slug_from_uri('yammer.nitrousapp.com:65333', '.nitrousapp.com'), 'yammer')
    assert.are.equal(common.get_slug_from_uri('dropbox.nitrousapp.com', '.nitrousapp.com'), 'dropbox')
    assert.are.equal(common.get_slug_from_uri('hello.yammer.nitrousapp.com:65333', '.nitrousapp.com'), 'yammer')
    assert.are.equal(common.get_slug_from_uri('hello.dropbox.nitrousapp.com', '.nitrousapp.com'), 'dropbox')
    assert.are.equal(common.get_slug_from_uri('umm.hello.yammer.nitrousapp.com:65333', '.nitrousapp.com'), 'yammer')
    assert.are.equal(common.get_slug_from_uri('trailingdot.nitrousapp.com.', '.nitrousapp.com'), 'trailingdot')
    assert.are.equal(common.get_slug_from_uri('.aaa.com.', '.nitrousapp.com'), nil)
    assert.are.equal(common.get_slug_from_uri('.nitrousapp.com.', '.nitrousapp.com'), nil)
  end)
end)