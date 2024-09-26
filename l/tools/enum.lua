
-- very simple enum tool

-- from a list of strings, it creates a <string> : <string> mapping.
local function new(strings)
    local ret = {}
    for _, v in ipairs(strings) do
        ret[v] = v
    end

    setmetatable(ret, {
        __index = function(t, k)
            if t[k] == nil then
                error("value " .. tostring(k) .. " does not exist in enum" .. tostring(k) .. ".")
            end
        end,
        __newindex = function(t, k, v)
            print("cannot add key/value (" .. tostring(k) .. "-" .. tostring(v) .. ") to enum " .. tostring(t) .. ".")
        end,
    })

    return ret
end

local function iter(enum)
    return pairs(enum)
end

return {
    new = new,
    iter = iter,
}
