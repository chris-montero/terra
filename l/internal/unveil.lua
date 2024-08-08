
local function formatValue(v)
    local output = ""
    if type(v) == "nil" then
        output = "nil"
    elseif type(v) == "boolean" then
        output = tostring(v)
    elseif type(v) == "number" then
        output = tostring(v)
    elseif type(v) == "string" then
        output = tostring(v)
    elseif type(v) == "function" then
        output = tostring(v)
    elseif type(v) == "userdata" then -- TODO: test for this
        output = tostring(v)
    elseif type(v) == "thread" then -- TODO: test for this
        output = tostring(v)
    elseif type(v) == "table" then
        error("table shouldn't have been given to 'formatValue'")
    end
    return output
end

local formatTable

-- local function formatArray(indent, arr, ignore_fields)

--     local output = ""
--     local consecutiveNilTimes = 0
--     local maxNum = table.maxn(arr)

--     local i = 1
--     while i <= maxNum do
--         if arr[i] == nil then
--             for k = i, maxNum do
--                 if arr[k] == nil then
--                     consecutiveNilTimes = consecutiveNilTimes + 1
--                 else
--                     local startingNilIndex = i
--                     local endingNilIndex = k - 1
--                     if consecutiveNilTimes > 5 then
--                         output = output
--                             .. string.rep(' ', indent * 4)
--                             .. '['
--                             .. tostring(startingNilIndex)
--                             .. ']'
--                             .. ' = '
--                             .. tostring(arr[startingNilIndex])
--                             .. '\n'
--                         output = output
--                             .. string.rep(' ', indent * 4)
--                             .. '.'
--                             .. '\n'
--                             .. string.rep(' ', indent * 4)
--                             .. '.'
--                             .. '\n'
--                             .. string.rep(' ', indent * 4)
--                             .. '.'
--                             .. '\n'
--                         output = output
--                             .. string.rep(' ', indent * 4)
--                             .. '['
--                             .. tostring(endingNilIndex)
--                             .. ']'
--                             .. ' = '
--                             .. tostring(arr[endingNilIndex])
--                             .. '\n'
--                     else
--                         for j = startingNilIndex, endingNilIndex do
--                             output = output
--                                 .. string.rep(' ', indent * 4)
--                                 .. '['
--                                 .. tostring(j)
--                                 .. ']'
--                                 .. ' = '
--                                 .. tostring(arr[j])
--                                 .. '\n'
--                         end
--                     end
--                     i = k
--                     consecutiveNilTimes = 0
--                 end
--             end
--         elseif type(arr[i]) == "table" then
--             output = output
--                 .. string.rep(' ', indent * 4)
--                 .. '['
--                 .. tostring(i)
--                 .. ']'
--                 .. ' = '
--                 .. '{'
--                 .. formatTable(indent + 1, arr[i], ignore_fields)
--                 .. string.rep(' ', indent * 4)
--                 .. '}'
--                 .. '\n'
--             i = i + 1
--         else
--             output = output
--                 .. string.rep(' ', indent * 4)
--                 .. '['
--                 .. tostring(i)
--                 .. ']'
--                 .. ' = '
--                 .. tostring(arr[i])
--                 .. '\n'
--             i = i + 1
--         end
--     end
--     return output
-- end

local function formatArray(indent, arr, ignore_fields)

    local output = ""
    local consecutiveNilTimes = 0
    local maxNum = table.maxn(arr)

    local i = 1
    while i <= maxNum do
        if arr[i] == nil then
            i = i + 1
        elseif type(arr[i]) == "table" then
            output = output
                .. string.rep(' ', indent * 4)
                .. '['
                .. tostring(i)
                .. ']'
                .. ' = '
                .. '{'
                .. formatTable(indent + 1, arr[i], ignore_fields)
                .. string.rep(' ', indent * 4)
                .. '}'
                .. '\n'
            i = i + 1
        else
            output = output
                .. string.rep(' ', indent * 4)
                .. '['
                .. tostring(i)
                .. ']'
                .. ' = '
                .. tostring(arr[i])
                .. '\n'
            i = i + 1
        end
    end
    return output
end


formatTable = function(indent, tab, ignore_fields)
    local array = {}
    local keyValue = {}

    -- we get the values for the array table and the key value table
    -- separately because we want to detect gaps in the array table properly
    for i=1, table.maxn(tab) do
        array[i] = tab[i]
    end

    for k, v in pairs(tab) do
        if type(k) == "string" then
            keyValue[k] = v
        end
    end
    local output = ""

    output = output .. '\n'
    output = output .. formatArray(indent, array, ignore_fields)

    for k, v in pairs(keyValue) do
        if type(v) == "table" then
            if ignore_fields[k] == nil then
                output = output
                    .. string.rep(' ', indent * 4)
                    .. '"'
                    .. k
                    .. '"'
                    .. ' = '
                    .. '{'
                    .. formatTable(indent + 1, v, ignore_fields)
                    .. string.rep(' ', indent * 4)
                    .. '}'
                    .. '\n'
            else
                output = output
                    .. string.rep(' ', indent * 4)
                    .. '"'
                    .. k
                    .. '"'
                    .. ' = '
                    .. '<'
                    .. "IGNORE_FIELD"
                    .. '>'
                    .. '\n'
            end
        elseif type(v) == "string" then
            output = output
                .. string.rep(' ', indent * 4)
                .. k
                .. ' = '
                .. '"'
                .. v
                .. '"'
                .. '\n'
        else
            output = output
                .. string.rep(' ', indent * 4)
                .. k
                .. ' = '
                .. tostring(v)
                .. '\n'
        end
    end

    return output
end

local function _create_output(tab, config)
    config = config or {}

    -- list out configurations here for clarity
    local ignore_fields = config.ignore_fields or {}

    if type(tab) ~= "table" then
        return tostring(tab) .. '\n'
    else
        return "table = {" .. formatTable(1, tab, ignore_fields) .. "}\n"
    end
end

local dump = function(t, config)
    io.write(_create_output(t, config))
end

return {
    _create_output = _create_output, -- used for testing
    dump = dump
}
