local redis = require "resty.redis"

local _M = {}

-- To get redis client
function _M.get_client()
  local red = redis:new()

  red:set_timeout(1000)

  local ok, err = red:connect("127.0.0.1", 6379)
  if not ok then
    return nil, err
  end

  return red, nil
end

return _M