local redis = require "resty.redis"
local _M = {}

-- To get redis client
function _M.get_redis_client()
    local red = redis:new()

    red:set_timeout(1000)

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        return nil, err
    end

    return red, nil
end

-- To parse container slug from url
function _M.get_slug_from_uri(uri, base_domain)
    local last, _ = string.find(uri, base_domain)
    if not last then
        return nil
    end

    local first
    last = last - 1

    for i = last, 1, -1  do
        local c = uri:sub(i,i)
        if c == "." then break end
        first = i
    end

    return string.sub(uri, first, last)
end

function _M.print_table(hash)
    for key,value in pairs(hash) do
        ngx.log(ngx.INFO, "key: ", key, " value: ", value)
    end
end

function _M.split(value, delimiter)
    local words = {}
    local index = 1
    for word in string.gmatch(value, delimiter) do
        words[index] = word
        index = index + 1
    end

    return words
end

function _M.isWebsocket()
    local request_headers = ngx.req.get_headers()
    if request_headers["Upgrade"] == 'websocket' and request_headers["Connection"] == 'upgrade' then
        return true
    end
    return false
end

function _M.https_request(cafile, ip, port, path, secret)
    local https = require("ssl.https")
    local full_url = "https://"..ip..":"..port..path
    local response_body = {}
    local params = {
        url = full_url,
        protocol = "tlsv1",
        sink = ltn12.sink.table(response_body),
        options = "all",
        verify = "peer",
        cafile = cafile,
        headers = {
            ["X-Freighter-Secret"] = secret,
        },
    }
    local one, code, headers, status = https.request(params)
    ngx.log(ngx.INFO, code, ", ", status)

    return table.concat(response_body)
end

return _M