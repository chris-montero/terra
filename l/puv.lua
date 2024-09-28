-- promise-based wrapper around luv

local luv = require("luv")
local tt_promise = require("terra.tools.promise")

local function mkdir(path)
    local prom = tt_promise.new()

    luv.fs_mkdir(path, tonumber('755', 8), function(err, success)
        if err ~= nil then
            prom:reject(err)
        else
            prom:resolve(success)
        end
    end)
    return prom
end

local function tcp_new()
    local prom = tt_promise.new()
    local tcp, err_msg, err_type = luv.new_tcp()
    if tcp == nil then
        prom:reject(err_msg)
    else
        prom:resolve(tcp)
    end
    return prom
end

local function tcp_connect(tcp, host, port)

    local p = tt_promise.new()
    luv.tcp_connect(tcp, host, port, function(err)
        if err ~= nil then
            p:reject(err)
        else
            p:resolve(tcp)
        end
    end)
    return p
end

local function tcp_write(tcp, data)

    local p = tt_promise.new()

    luv.write(tcp, data, function(err)
        if err ~= nil then
            p:reject(err)
        else
            p:resolve(tcp)
        end
    end)

    return p
end

return {
    mkdir = mkdir,
    tcp_new = tcp_new,
    tcp_connect = tcp_connect,
    tcp_write = tcp_write
}
