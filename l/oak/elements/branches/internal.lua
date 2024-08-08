
local t_element = require("terra.element")
local toe_element = require("terra.oak.elements.element")

local function get_spacing_between_children(children_amt, spacing)
    -- if we have 0 or 1 children, there's 0 spacing
    -- if there's 2 or more, we have (num_children - 1) * spacing
    if children_amt >= 2 then
        return spacing * (children_amt - 1)
    end
    return 0
end

local function shadow_dimensionate_and_position(shadow, avail_w, avail_h)

    local edge_width = shadow.edge_width or 0
    local shadow_w = avail_w + (edge_width * 2)
    local shadow_h = avail_h + (edge_width * 2)

    -- TODO: make sure the shadow x and y is always on integer coordinates
    local shadow_edge_width = shadow.edge_width or 0
    -- always place shadow in the center of the parent geometry, regardless of 
    -- what halign/valign the shadow has
    local shadow_x = - shadow_edge_width
    local shadow_y = - shadow_edge_width

    if shadow.offset_x ~= nil then shadow_x = shadow_x + shadow.offset_x end
    if shadow.offset_y ~= nil then shadow_y = shadow_y + shadow.offset_y end

    return {
        x = shadow_x,
        y = shadow_y,
        width = shadow_w,
        height = shadow_h,
        element = shadow,
    }
end

local function set_spacing(elem, value)
    toe_element.default_oak_prop_set(elem, "spacing", value)
end

return {
    POSITION_START = 1,
    POSITION_START_END = 2,
    POSITION_START_CENTER_END = 3,

    get_spacing_between_children = get_spacing_between_children,
    shadow_dimensionate_and_position = shadow_dimensionate_and_position,

    set_spacing = set_spacing,
}
