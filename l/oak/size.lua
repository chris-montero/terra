
local SIZE_SHRINK = { type = 1 }
local SIZE_FILL = { type = 2 }

local lib = {
    FILL = SIZE_FILL,
    SHRINK = SIZE_SHRINK,
}

local function is_shrink(v)
    if v == nil then return true end -- nil always means "shrink"
    return type(v) == "table" and v.type == 1
end

local function is_fill(v)
    return type(v) == "table" and v.type == 2
end

lib.is_shrink = is_shrink
lib.is_fill = is_fill

return lib

