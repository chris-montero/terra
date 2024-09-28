
-- a simple library for working with strings in lua

-- always use this table to represent the empty sstr
-- TODO: is this safe?
local sstr_empty = {}

local function sstr_from_string(str)
    -- store the string as a list because it's costly in lua to keep 
    -- splitting and splicing and joining etc regular strings.
    local ret = {}
    for i=1, #str do
        ret[i] = string.sub(str, i, i)
    end
    return ret
end

local function sstr_to_string(sstr)
    return table.concat(sstr)
end

local function sstr_length(sstr)
    return #sstr
end

local function sstr_print(sstr)
    for _, c in ipairs(sstr) do
        io.stdout:write(c)
    end
    io.stdout:write("\n")
end

-- returns a new value of type "sstr" that is composed of the characters 
-- that exist in `sstr` between `p1` and `p2`. returns nil if it can't.
local function sstr_slice(sstr, p1, p2)

    if p1 > p2 then return nil end
    if p1 > sstr_length(sstr) then return nil end

    if p2 > sstr_length(sstr) then p2 = #sstr end -- TODO: should this loop?

    local ret = {}

    for i=p1, p2 do
        table.insert(ret, sstr[i])
    end

    return ret
end

local function _matches(sstr1, start, sstr2)
    if sstr_length(sstr2) > sstr_length(sstr1) then return false end
    if start > sstr_length(sstr1) - sstr_length(sstr2) + 1 then return false end
    -- print("checking matches:", start)

    -- print("does it match:", sstr_to_string(sstr1), start, sstr_to_string(sstr2))
    -- print("start, end", start, start+sstr_length(sstr2))
    -- for i=start, start + sstr_length(sstr2) do
    for i=1, sstr_length(sstr2) do
        -- print(sstr1[i + start - 1], sstr2[i])
        if sstr1[i + start - 1] ~= sstr2[i] then 
            -- print("doesnt")
            return false 
        end
    end
    -- print("MATCH")
    return true
end

-- returns true if `sstr` starts with `sstr_with`
local function sstr_starts_with(sstr, sstr_with)
    return _matches(sstr, 1, sstr_with)
end

local function sstr_ends_with(sstr, sstr_with)
    return _matches(sstr, sstr_length(sstr) - sstr_length(sstr_with) + 1, sstr_with)
end

local function sstr_find_iter(sstr, sstr_thing)

    local p = 1
    local max = sstr_length(sstr) - sstr_length(sstr_thing) + 1

    return function()
        while p <= max do
            if _matches(sstr, p, sstr_thing) then
                local ret = p
                p = p + sstr_length(sstr_thing)
                return ret
            else
                p = p + 1
            end
        end
    end
end

-- split `sstr` in a list of sstrs based on pattern `sstr_sep`
local function sstr_split_iter(sstr, sstr_sep)

    local is_first = true
    local from = 1

    local find_next = sstr_find_iter(sstr, sstr_sep) 
    local first_run = true
    local last_run = false

    return function()
        if last_run == true then return nil end -- exit the iterator

        local i = find_next()

        if first_run then
            first_run = false
            if i == 1 then
                from = i + sstr_length(sstr_sep)
                i = find_next()
            end
        end

        if i == nil then
            -- this can return nil, which will also correctly exit the iterator
            local s = sstr_slice(sstr, from, sstr_length(sstr)) 
            last_run = true
            return s
        else
            local s = sstr_slice(sstr, from, i-1) or sstr_empty
            from = i + sstr_length(sstr_sep)
            return s
        end
    end
end

-- returns an iterator, which, upon being called, returns 
-- (index, character) pairs
local function sstr_iter_char(sstr_value)
    return ipairs(sstr_value)
    -- local i = 1
    -- return function()
    --     while i <= sstr_length(sstr_value) do
    --         local c = sstr_value[i]
    --         i = i + 1
    --         return c
    --     end
    -- end
end

local function concat(sstr_list)
    local concatenated = {}
    for _, sstr_value in ipairs(sstr_list) do
        for _, c in sstr_iter_char(sstr_value) do
            table.insert(concatenated, c)
        end
    end
    return concatenated
end

return {
    empty = sstr_empty,

    from_string = sstr_from_string,
    to_string = sstr_to_string,

    concat = concat,
    starts_with = sstr_starts_with,
    ends_with = sstr_ends_with,
    slice = sstr_slice,
    length = sstr_length,
    print = sstr_print,
    find_iter = sstr_find_iter,
    split_iter = sstr_split_iter,
}
