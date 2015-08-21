local redis = require "resty.redis"
local settings = require "settings"

local _M = {}

-- To get redis client
function _M.get_client()
  local red = redis:new()

  red:set_timeout(settings.redis_timeout)

  local ok, err = red:connect(settings.redis_host, settings.redis_port)
  if not ok then
    return nil, err
  end

  if settings.redis_database ~= nil then
    local err = red:select(settings.redis_database)
    if not err then
      ngx.log(ngx.ERR, "failed to select redis database: ", err)
      return ngx.exit(500)
    end
  end

  return red, nil
end

return _M