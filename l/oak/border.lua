
local _BORDER_EACH = 1

-- TODO: I think it'd be better to make the border an element like any other
local function get_border_width(element)
    local bg = element.bg
    if element.bg == nil then return 0 end
    if bg.border_width == nil then return 0 end
    return bg.border_width
end

local function get_border_radius(element)
    local bg = element.bg
    if element.bg == nil then return 0 end
    return bg.border_radius or 0
end

local function radius_each(args)

    args.top_left = args.top_left or 0
    args.top_right = args.top_right or 0
    args.bottom_right = args.bottom_right or 0
    args.bottom_left = args.bottom_left or 0
    args.border_type = _BORDER_EACH

    assert(type(args.top_left) == "number", "'.top_left' should be number, got: " .. tostring(top_left))
    assert(type(args.top_right) == "number", "'.top_right' should be number, got: " .. tostring(top_right))
    assert(type(args.bottom_right) == "number", "'.bottom_right' should be number, got: " .. tostring(bottom_right))
    assert(type(args.bottom_left) == "number", "'.bottom_left' should be number, got: " .. tostring(bottom_left))

    return args
end

-- TODO: just return numbers here instead of a table
local function standardize_radius(border_radius)

    if border_radius == nil then
        return {
            top_left = 0,
            top_right = 0,
            bottom_right = 0,
            bottom_left = 0,
        }
    elseif type(border_radius) == "number" then
        return {
            top_left = border_radius,
            top_right = border_radius,
            bottom_right = border_radius,
            bottom_left = border_radius,
        }
    else -- border_each
        return {
            top_left = border_radius.top_left,
            top_right = border_radius.top_right,
            bottom_right = border_radius.bottom_right,
            bottom_left = border_radius.bottom_left,
        }
    end
end

return {
    get_width = get_border_width,
    get_radius = get_border_radius,

    radius_each = radius_each,
    standardize_radius = standardize_radius,
}

