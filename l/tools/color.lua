-- Copyright (c) 2024 Chris Montero

local COLOR_RGB = 1
local COLOR_RGBA = 2
local COLOR_HSL = 3
local COLOR_HSLA = 4

local function _clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function _parse_string(str)
    assert(string.match(str, "^#%x+$") ~= nil,
        [[the string supplied to should have one '#' character, followed by six 
        or eight hexadecimal digits. Got: ]] .. str
    )

    local str_numbers = string.sub(str, 2, string.len(str))

    -- make sure the values stay between 0 and 1
    local r = _clamp(tonumber(string.sub(str_numbers, 1, 2), 16) / 255, 0, 1)
    local g = _clamp(tonumber(string.sub(str_numbers, 3, 4), 16) / 255, 0, 1)
    local b = _clamp(tonumber(string.sub(str_numbers, 5, 6), 16) / 255, 0, 1)
    local a
    if string.len(str_numbers) == 8 then
        a = _clamp(tonumber(string.sub(str_numbers, 7, 8), 16) / 255, 0, 1)
    end

    return {
        r = r,
        g = g,
        b = b,
        a = a
    }

end

local function rgb(r, g, b)

    return {
        _color_type = COLOR_RGB,
        r = _clamp(r, 0, 1),
        g = _clamp(g, 0, 1),
        b = _clamp(b, 0, 1),
    }
end


local function rgba(r, g, b, a)

    return {
        _color_type = COLOR_RGBA,
        r = _clamp(r, 0, 1),
        g = _clamp(g, 0, 1),
        b = _clamp(b, 0, 1),
        a = _clamp(a, 0, 1),
    }
end

local function hsl(h, s, l)

    return {
        _color_type = COLOR_HSL,
        -- TODO: fix. the user first sets the hue value from 0 to 360, but then
        -- he'll be surprised to see that the value internally goes from 0 to 1
        h = _clamp(h, 0, 360) / 360,
        s = _clamp(s, 0, 1),
        l = _clamp(l, 0, 1),
    }
end

local function hsla(h, s, l, a)

    return {
        _color_type = COLOR_HSLA,
        -- TODO: fix. the user first sets the hue value from 0 to 360, but then
        -- he'll be surprised to see that the value internally goes from 0 to 1
        h = _clamp(h, 0, 360) / 360,
        s = _clamp(s, 0, 1),
        l = _clamp(l, 0, 1),
        a = _clamp(a, 0, 1)
    }
end

local function rgb_to_hsl(color)
    local r = color.r
    local g = color.g
    local b = color.b

    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l

    l = (max + min) / 2

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
    end

    return {
        _color_type = COLOR_HSL,
        h = h,
        s = s,
        l = l
    }
end

local function rgba_to_hsla(color)
    local conv = rgb_to_hsl(color)
    conv.a = color.a
    return conv
end

local function hsl_to_rgb(color)
    local r, g, b
    local h, s, l = color.h, color.s, color.l

    if s == 0 then
        r, g, b = l, l, l -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0   then t = t + 1 end
            if t > 1   then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end

        local q
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
    end

    return {
        _color_type = COLOR_RGB,
        r = r,
        g = g,
        b = b
    }
end

local function hsla_to_rgba(color)
    local conv = hsl_to_rgb(color)
    conv.a = color.a
    return conv
end

-- local function lighten(color, amt)
--     return {
--         _color_type = COLOR_RGB,
--         r = _clamp(color.r + amt, 0, 1),
--         g = _clamp(color.g + amt, 0, 1),
--         b = _clamp(color.b + amt, 0, 1)
--     }
-- end

local function rgb_from_string(str)

    local parsed_string = _parse_string(str)
    return {
        _color_type = COLOR_RGB,
        r = parsed_string.r,
        g = parsed_string.g,
        b = parsed_string.b,
    }

end

local function rgba_from_string(str)

    local parsed = _parse_string(str)
    assert(parsed.a ~= nil,
        [[the string given must have a '#' character, followed by 8 hexadecimal 
        digits. Got: ]] .. str
    )

    return {
        _color_type = COLOR_RGBA,
        r = parsed.r,
        g = parsed.g,
        b = parsed.b,
        a = parsed.a
    }
end

local function is_color(val)
    if val._color_type == nil then
        return false
    end
    if val._color_type < COLOR_RGB then
        return false
    end
    if val._color_type > COLOR_HSLA then
        return false
    end
    return true
end

return {

    COLOR_RGB = COLOR_RGB,
    COLOR_RGBA = COLOR_RGBA,
    COLOR_HSL = COLOR_HSL,
    COLOR_HSLA = COLOR_HSLA,

    rgb = rgb,
    rgba = rgba,
    hsl = hsl,
    hsla = hsla,

    is_color = is_color,
    -- lighten = lighten,

    rgb_to_hsl = rgb_to_hsl,
    rgba_to_hsla = rgba_to_hsla,
    hsl_to_rgb = hsl_to_rgb,
    hsla_to_rgba = hsla_to_rgba,

    rgb_from_string = rgb_from_string,
    rgba_from_string = rgba_from_string,

}
