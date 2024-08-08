
local tt_table = require("terra.tools.table")

local to_border = require("terra.oak.border")
local to_source = require("terra.oak.source")
local to_shape = require("terra.oak.shape")

local toe_internal = require("terra.oak.elements.internal")
local toe_element = require("terra.oak.elements.element")

local toel_leaf = require("terra.oak.elements.leaves.leaf")

local function draw_background(bg_elem, cr, width, height)
    local bg_source = bg_elem.source

    if bg_source == nil then return end

    local br_top_left, br_top_right, br_bottom_right, br_bottom_left
    do
        local border_radius = to_border.standardize_radius(bg_elem.border_radius or 0)
        br_top_left = border_radius.top_left or 0
        br_top_right = border_radius.top_right or 0
        br_bottom_right = border_radius.bottom_right or 0
        br_bottom_left = border_radius.bottom_left or 0
    end
    local border_width = bg_elem.border_width or 0

    if br_top_left > 0 or
        br_top_right > 0 or
        br_bottom_right > 0 or
        br_bottom_left > 0
    then
        -- we have rounded borders, so use a rounded rectangle as the path
        cr:save()
        cr:translate(border_width, border_width)
        to_shape.rounded_rectangle_each(
            cr,
            width - (border_width * 2),
            height - (border_width * 2),
            br_top_left,
            br_top_right,
            br_bottom_right,
            br_bottom_left
        )
        cr:restore()
    else
        cr:rectangle(
            border_width,
            border_width,
            width - (border_width * 2),
            height - (border_width * 2)
        )
    end

    cr:set_source(to_source.to_cairo_source(bg_source))
    cr:fill()
end

local function draw_border(bg_elem, cr, width, height)

    local border_width = bg_elem.border_width

    if border_width == nil then return end

    local br_top_left, br_top_right, br_bottom_right, br_bottom_left
    do
        local border_radius = to_border.standardize_radius(bg_elem.border_radius or 0)
        br_top_left = border_radius.top_left or 0
        br_top_right = border_radius.top_right or 0
        br_bottom_right = border_radius.bottom_right or 0
        br_bottom_left = border_radius.bottom_left or 0
    end

    -- local border_radius = bg_elem.border_radius or 0
    local border_source = bg_elem.border_source or stdcolor.rgb(0, 0, 0) -- black default color for border
    cr:push_group_with_content(lgi.cairo.Content.ALPHA)
    cr.fill_rule = lgi.cairo.FillRule.EVEN_ODD

    if br_top_left > 0 or
        br_top_right > 0 or
        br_bottom_right > 0 or
        br_bottom_left > 0
    then

        to_shape.rounded_rectangle_each(
            cr,
            width,
            height,
            br_top_left + border_width,
            br_top_right + border_width,
            br_bottom_right + border_width,
            br_bottom_left + border_width
        )

        -- to_shape.rounded_rectangle(cr, width, height, border_radius + border_width)
        cr:translate(border_width, border_width)
        -- to_shape.rounded_rectangle(cr, width - (border_width * 2), height - (border_width * 2), border_radius)
        to_shape.rounded_rectangle_each(
            cr,
            width - (border_width * 2),
            height - (border_width * 2),
            br_top_left,
            br_top_right,
            br_bottom_right,
            br_bottom_left
        )
        cr:fill()
    else
        cr:rectangle(0, 0, width, height)
        cr:rectangle(
            border_width,
            border_width,
            width - (border_width * 2),
            height - (border_width * 2)
        )
        cr:fill()
    end
    local msk = cr:pop_group()
    cr:set_source(to_source.to_cairo_source(border_source))
    cr:mask(msk)
    finish_pattern_surface(msk)
end

local function bg_draw(bg, cr, width, height)
    cr:save()
    draw_border(bg, cr, width, height)
    cr:restore()
    draw_background(bg, cr, width, height)
end

local function set_source(bg, source)
    toe_element.default_oak_prop_set(bg, "source", source)
end

local function new(args)

    local bg_defaults = {

        -- TODO: uncomment these
        -- width = ou_internal.SIZE_FILL,
        -- height = ou_internal.SIZE_FILL,

        -- part of the interface to be a <terra.oak.element>
        oak_handle_attach_to_parent_element = toe_internal.element_common_handle_attach_to_parent_element,
        oak_handle_detach_from_parent_element = toe_internal.element_common_handle_detach_from_parent_element,

        -- this element happens to draw something
        oak_draw = bg_draw,

        -- TODO: implement this
        set_source = set_source,

        -- TODO: make bg also work with halign and valign
    }

    return tt_table.crush(toel_leaf.new(), bg_defaults, args)
end

return {
    new = new,

    oak_draw = bg_draw,
    set_source = set_source,
}

