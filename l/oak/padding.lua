local _PADDING_AXIS = 1
local _PADDING_EACH = 2

local function axis(args)

    local x = args.x or 0
    local y = args.y or 0
    assert(type(x) == "number", "key 'x' should be number, got: " .. tostring(x))
    assert(type(y) == "number", "key 'y' should be number, got: " .. tostring(y))

    return {
        type = _PADDING_AXIS,
        x = x,
        y = y
    }
end

local function each(args)

    local top = args.top or 0
    local right = args.right or 0
    local bottom = args.bottom or 0
    local left = args.left or 0

    assert(type(top) == "number", "key 'top' should be number, got: " .. tostring(top))
    assert(type(right) == "number", "key 'right' should be number, got: " .. tostring(right))
    assert(type(bottom) == "number", "key 'bottom' should be number, got: " .. tostring(bottom))
    assert(type(left) == "number", "key 'left' should be number, got: " .. tostring(left))

    return {
        type = _PADDING_EACH,
        top = top,
        right = right,
        bottom = bottom,
        left = left,
    }
end

local function is_each(p)
    if p.type == _PADDING_EACH then return true end
    return false
end
local function is_axis(p)
    if p.type == _PADDING_AXIS then return true end
    return false
end

-- TODO: just return numbers here, instead of tables
local function standardize(pad)
    if type(pad) == "number" then
        return {
            top = pad,
            right = pad,
            bottom = pad,
            left = pad,
        }
    elseif is_axis(pad) then
        return {
            top = pad.y,
            right = pad.x,
            bottom = pad.y,
            left = pad.x,
        }
    else -- pad.type == PADDING_EACH
        return {
            top = pad.top,
            right = pad.right,
            bottom = pad.bottom,
            left = pad.left,
        }
    end
end

return {
    is_each = is_each,
    is_axis = is_axis,
    each = each,
    axis = axis,
    standardize = standardize,
}
