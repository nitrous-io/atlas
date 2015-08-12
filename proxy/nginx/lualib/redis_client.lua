local redis = require "resty.redis"
local settings = require "settings"

local _M = {}

-- To get redis client
function _M.get_client()
  local red = redis:new()

  red:set_timeout(1000)

  local ok, err = red:connect("127.0.0.1", 6379)
  if not ok then
    return nil, err
  end

  if settings.redis_database ~= nil then
    local err = red:select(settings.redis_database)
    if not err then
      ngx.log(ngx.ERR, "failed to select redis database: ", err)
      return ngx.exit(404)
    end
  end

  return red, nil
end

return _M