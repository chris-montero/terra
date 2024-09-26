
local luv = require("luv")
local tstation = require("tstation")

local t_promise = require("terra.promise")
local t_puv = require("terra.puv")

local function _make_id(host, port)
    return tostring(host) .. '/' .. tostring(port)
end

local function _ensure_connection(app, host, port)

    local id = _make_id(host, port)
    local conn = app._tcp_conns[id]
    if conn == nil then
        return t_puv.tcp_new()
            :next(function(tcp)
                app._tcp_conns[id] = tcp
                return t_puv.tcp_connect(tcp, host, port)
            end)
    else
        local p = t_promise.new()
        p:resolve(conn)
        return p
    end
end

local function listen_by_line(app, host, port, sig_succ, sig_fail)
    _ensure_connection(app, host, port)
        :next(function(tcp)
            luv.read_start(tcp, function(err, data)
                if err ~= nil then
                    return tstation.emit(app.station, sig_fail, err)
                else
                    return tstation.emit(app.station, sig_succ, data)
                end
            end)
        end)
end

local function stop_listening(app, host, port)
end

local function write(app, host, port, data)
    _ensure_connection(app, host, port)
        :next(function(tcp)
            return t_puv.tcp_write(tcp, data)
        end)
end

return {
    listen_by_line = listen_by_line,
    stop_listening = stop_listening,
    write = write,
}

