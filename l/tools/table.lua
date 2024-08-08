
-- takes a variable number of tables and crushes each one onto the previous one.
-- Example:
-- * we have t1, t2, t3
-- * create t0
-- * all properties of t1 go into t0
-- * all properties of t2 go into t0
-- * all properties of t3 go into t0
-- * return t0
local function crush(...)
    local t = {}

    local tbls = {...}
    for i=#tbls, 1, -1 do
        local tbl = tbls[i]

        for k, v in pairs(tbl) do
            if t[k] == nil then
                t[k] = v
            end
        end

    end

    return t
end


return {
    crush = crush,
}

