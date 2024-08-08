
local lgi = require("lgi")
local stdcolor = require("stdcolor")

local SOURCE_LINEAR_GRADIENT = 3
local SOURCE_RADIAL_GRADIENT = 4
local SOURCE_IMAGE = 5

local function _check_point(args)
    assert(type(args.x) == "number", "x should be a number")
    assert(type(args.y) == "number", "y should be a number")
end

local function stop(offset, color)
    assert(stdcolor.is_color(color))

    return {
        offset = offset,
        color = color,
    }
end

local function linear_gradient(point1, point2, stops)

    _check_point(point1)
    _check_point(point2)

    return {
        _source_type = SOURCE_LINEAR_GRADIENT,
        begin = point1,
        finish = point2,
        stops = stops,
    }
end

local function _add_color_stop(linpat, stp)

    if stp.color._color_type == stdcolor.COLOR_RGB then
        lgi.cairo.GradientPattern.add_color_stop_rgb(
            linpat,
            stp.offset,
            stp.color.r,
            stp.color.g,
            stp.color.b
        )
    elseif stp.color._color_type == stdcolor.COLOR_RGBA then
        lgi.cairo.GradientPattern.add_color_stop_rgba(
            linpat,
            stp.offset,
            stp.color.r,
            stp.color.g,
            stp.color.b,
            stp.color.a
        )
    elseif stp.color._color_type == stdcolor.COLOR_HSL then
        local conv = stdcolor.hsl_to_rgb(stp.color)
        lgi.cairo.GradientPattern.add_color_stop_rgb(
            linpat,
            stp.offset,
            conv.r,
            conv.g,
            conv.b
        )
    elseif stp.color._color_type == stdcolor.COLOR_HSLA then
        local conv = stdcolor.hsla_to_rgba(stp.color)
        lgi.cairo.GradientPattern.add_color_stop_rgba(
            linpat,
            stp.offset,
            conv.r,
            conv.g,
            conv.b,
            conv.a
        )
    end
end

local function to_cairo_source(src)

    if src._color_type ~= nil then

        if src._color_type == stdcolor.COLOR_RGB then
            return lgi.cairo.Pattern.create_rgb(src.r, src.g, src.b)
        elseif src._color_type == stdcolor.COLOR_RGBA then
            return lgi.cairo.Pattern.create_rgba(src.r, src.g, src.b, src.a)
        elseif src._color_type == stdcolor.COLOR_HSL then
            local conv = stdcolor.hsl_to_rgb(src)
            return lgi.cairo.Pattern.create_rgb(conv.r, conv.g, conv.b)
        elseif src._color_type == stdcolor.COLOR_HSLA then
            local conv = stdcolor.hsla_to_rgba(src)
            return lgi.cairo.Pattern.create_rgba(conv.r, conv.g, conv.b, conv.a)
        end

    elseif src._source_type ~= nil then

        if src._source_type == SOURCE_LINEAR_GRADIENT then
            local linpat = lgi.cairo.Pattern.create_linear(
                src.begin.x, src.begin.y,
                src.finish.x, src.finish.y
            )
            for _, s in ipairs(src.stops) do
                _add_color_stop(linpat, s)
            end
            return linpat
        end

    end
end

return {
    linear_gradient = linear_gradient,
    stop = stop,
    to_cairo_source = to_cairo_source,
}

