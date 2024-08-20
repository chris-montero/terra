
local tt_table = require("terra.tools.table")

local to_padding = require("terra.oak.padding")
local to_size = require("terra.oak.size")
local to_align = require("terra.oak.align")
local to_border = require("terra.oak.border")
local to_internal = require("terra.oak.internal")

local toe_element = require("terra.oak.elements.element")
local toe_internal = require("terra.oak.elements.internal")

local toeb_internal = require("terra.oak.elements.branches.internal")
local toeb_branch = require("terra.oak.elements.branches.branch")

local function el_calculate_minimum_dimensions(el, constraint_w, constraint_h)

    local el_bw = to_border.get_width(el)
    local standardized_padding = to_padding.standardize(el.padding or 0)

    local min_w = standardized_padding.left + standardized_padding.right + (el_bw * 2)
    local min_h = standardized_padding.top + standardized_padding.bottom + (el_bw * 2)

    local max_w = 0
    local max_h = 0

    -- NOTE: only go through the children in the array portion of the table because
    -- we don't want the shadow or the bg to take up horizontal space
    for _, child in ipairs(el) do

        local child_bw = to_border.get_width(child)
        local child_standardized_padding = to_padding.standardize(child.padding or 0)
        local child_w, child_h = child.width, child.height

        if type(child_w) == "number" and type(child_h) == "number" then
            max_w = math.max(
                max_w,
                child_w
                    + (child_bw * 2)
                    + child_standardized_padding.left
                    + child_standardized_padding.right
            )
            max_h = math.max(
                max_h,
                child_h
                    + (child_bw * 2)
                    + child_standardized_padding.top
                    + child_standardized_padding.bottom
            )
        elseif type(child_w) == "number" and type(child_h) ~= "number" then
            local _, min_child_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(
                max_w,
                child_w
                    + (child_bw * 2)
                    + child_standardized_padding.left
                    + child_standardized_padding.right
            )
            max_h = math.max(max_h, min_child_h)
        elseif type(child_w) ~= "number" and type(child_h) == "number" then
            local min_child_w, _ = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(max_w, min_child_w)
            max_h = math.max(
                max_h,
                child_h
                    + (child_bw * 2)
                    + child_standardized_padding.top
                    + child_standardized_padding.bottom
            )
        else -- both are not numbers
            local min_child_w, min_child_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(max_w, min_child_w)
            max_h = math.max(max_h, min_child_h)
        end
    end

    return min_w + max_w, min_h + max_h
end


local function _dimensionate_single_child_el(el, child, avail_w, avail_h)

    local padd = el.padding or 0
    local standardized_padding = to_padding.standardize(padd)
    local padding_top = standardized_padding.top
    local padding_right = standardized_padding.right
    local padding_bottom = standardized_padding.bottom
    local padding_left = standardized_padding.left
    local child_bw = to_border.get_width(child)

    local child_w = 0
    local child_h = 0

    local function _calculate_non_shrink_width(c)
        if type(c.width) == "number" then
            return c.width + (child_bw * 2)
        else -- child.width == "fill"
            local remaining_w = avail_w - (padding_left + padding_right)
            if remaining_w - (child_bw * 2) > 0 then
                return remaining_w
            else
                return child_bw * 2
            end
        end
    end

    local function _calculate_non_shrink_height(c)
        if type(c.height) == "number" then
            return c.height + (child_bw * 2)
        else -- child.height == "fill"
            local remaining_h = avail_h - (padding_top + padding_bottom)
            if remaining_h - (child_bw * 2) > 0 then
                return remaining_h
            else
                return child_bw * 2
            end
        end
    end

    if to_size.is_shrink(child.width) and to_size.is_shrink(child.height) then
        child_w, child_h = child:oak_calculate_minimum_dimensions(nil, nil)

    elseif to_size.is_shrink(child.width) and not to_size.is_shrink(child.height) then
        local min_w, _ = child:oak_calculate_minimum_dimensions(nil, child_h)
        child_h = _calculate_non_shrink_height(child)
        child_w = min_w

    elseif not to_size.is_shrink(child.width) and to_size.is_shrink(child.height) then
        child_w = _calculate_non_shrink_width(child)
        local _, min_h = child:oak_calculate_minimum_dimensions(child_w, nil)
        child_h = min_h

    else -- neither are of type "shrink"
        child_w = _calculate_non_shrink_width(child)
        child_h = _calculate_non_shrink_height(child)

    end

    return {
        element = child,
        valign = child.valign or to_align.TOP,
        halign = child.halign or to_align.LEFT,
        width = child_w,
        height = child_h,
        offset_x = child.offset_x or 0,
        offset_y = child.offset_y or 0,
    }
end

local function el_dimensionate_children(el, avail_w, avail_h)

    local dimensionated_children_data = {
        available_width = avail_w,
        available_height = avail_h,
        standardized_padding = to_padding.standardize(el.padding or 0),
        parent_border_width = to_border.get_width(el)
    }

    do
        local shadow = el.shadow
        local bg = el.bg
        if shadow ~= nil then dimensionated_children_data.shadow = shadow end
        if bg ~= nil then dimensionated_children_data.bg = bg end
    end

    for _, child in ipairs(el) do
        table.insert(
            dimensionated_children_data,
            _dimensionate_single_child_el(el, child, avail_w, avail_h)
        )
    end

    return dimensionated_children_data
end

local function el_position_children(dimensionated_children_data)
    local available_width = dimensionated_children_data.available_width
    local available_height = dimensionated_children_data.available_height

    local padding_top, padding_right, padding_bottom, padding_left
    do
        local standardized_padding = dimensionated_children_data.standardized_padding
        padding_top = standardized_padding.top
        padding_right = standardized_padding.right
        padding_bottom = standardized_padding.bottom
        padding_left = standardized_padding.left
    end

    local parent_bw = dimensionated_children_data.parent_border_width

    local positioned_children_data = {}

    do -- add shadow and bg elements first

        -- Note: normally, elements should not be dimensionated here, only
        -- positioned. but it's such a trivial task that we just dimensionate 
        -- and position the shadow and bg here
        local shadow = dimensionated_children_data.shadow
        if shadow ~= nil then
            table.insert(positioned_children_data, toe_internal.shadow_dimensionate_and_position(
                shadow,
                available_width,
                available_height
            ))
        end

        local bg = dimensionated_children_data.bg
        if bg ~= nil then
            table.insert(positioned_children_data, {
                x = bg.offset_x or 0,
                y = bg.offset_y or 0,
                width = available_width,
                height = available_height,
                element = bg
            })
        end
    end

    for _, dimensionated_child in ipairs(dimensionated_children_data) do

        local child_w = dimensionated_child.width
        local child_h = dimensionated_child.height
        table.insert(positioned_children_data, {
            element = dimensionated_child.element, -- a reference to the child
            x = to_internal.align_on_secondary_axis(
                padding_left + parent_bw,
                padding_right + parent_bw,
                dimensionated_child.halign,
                available_width,
                child_w
            ) + dimensionated_child.offset_x,
            y = to_internal.align_on_secondary_axis(
                padding_top + parent_bw,
                padding_bottom + parent_bw,
                dimensionated_child.valign,
                available_height,
                child_h
            ) + dimensionated_child.offset_y,
            width = child_w - (parent_bw * 2),
            height = child_h - (parent_bw * 2),
        })
    end

    return positioned_children_data
end

-- TODO: make this function set the geometries of its subchildren directly
local function el_oak_geometrize_children(el, avail_w, avail_h)

    -- NOTE: this will return nil if this el has no shadow, no bg,
    -- and no sub-children
    if el.bg == nil and el.shadow == nil and #el == 0 then return nil end

    -- TODO: merge these two functions into one
    return el_position_children(
        el_dimensionate_children(el, avail_w, avail_h)
    )
end

local function new(args)
    if args == nil then args = {} end

    local el_defaults = {
        -- part of the interface to be a <terra.oak.elements.branch>
        oak_geometrize_children = el_geometrize_children,
        oak_calculate_minimum_dimensions = el_calculate_minimum_dimensions,
    }

    return tt_table.crush(toeb_branch.new(), el_defaults, args)
end

return {
    new = new,

    dimensionate_children = el_dimensionate_children,
    position_children = el_position_children,

    oak_geometrize_children = el_oak_geometrize_children,
    oak_calculate_minimum_dimensions = oak_el_calculate_minimum_dimensions,
}

