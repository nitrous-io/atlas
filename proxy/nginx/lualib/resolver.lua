local resolver = require "resty.dns.resolver"
local _M = {}

-- To resolver
function _M.get()
  local r, err = resolver:new{
    nameservers = {"8.8.8.8", "4.4.4.4"},
    retrans = 5,  -- 5 retransmissions on receive timeout
    timeout = 2000,  -- 2 sec
  }

  if not r then
    return nil, err
  end

  return r, err
end

return _M