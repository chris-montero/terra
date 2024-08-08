
local t_object = require("terra.object")
local tt_table = require("terra.tools.table")
-- local tstation = require("tstation")

local events = {
    MouseEnterEvent = "MouseEnterEvent",
    MouseLeaveEvent = "MouseLeaveEvent",
    MouseMotionEvent = "MouseMotionEvent",
    MouseClickEvent = "MouseClickEvent",
}

local function default_get_geometry(element)
    return element.geometry
end

local function default_set_geometry(element, x, y, width, height)
    element.geometry.x = x
    element.geometry.y = y
    element.geometry.width = width
    element.geometry.height = height
end

-- returns true if the given point exists inside the geometry of the given element.
local function contains_point(element, point_x, point_y)
    local geom = element.geometry
    if point_x < geom.x then return false end
    if point_x > geom.x + geom.width then return false end
    if point_y < geom.y then return false end
    if point_y > geom.y + geom.height then return false end
    return true
end

-- geometries can have floating point values. clip areas shouldn't. Given the
-- geometry of an element, this function returns a table with x, y, width, height
-- as integers
local function geometry_to_clip_area(geom) -- TODO: maybe rename this to "get_bounding_box"

    -- note: when clipping, these values should always be integers, in 
    -- order to have the rectangle be on pixel aligned coordinates. We do
    -- this because the cairo docs suggest this would be fastest.
    -- https://www.cairographics.org/FAQ/#clipping_performance
    local element_x_floor, element_x_fractional_part = math.modf(
        geom.x
    )
    local element_y_floor, element_y_fractional_part = math.modf(
        geom.y
    )

    return { -- TODO: dont return a table here
        x = element_x_floor,
        y = element_y_floor,
        width = math.ceil(geom.width + element_x_fractional_part),
        height = math.ceil(geom.height + element_y_fractional_part)
    }
end

local function new()

    local element_defaults = {
        geometry = {}, -- TODO: maybe make this `nil` at first until an element is attached
        get_geometry = default_get_geometry,
        set_geometry = default_set_geometry,
    }

    local element = tt_table.crush(t_object.new(), element_defaults)

    return element
end


return {
    new = new,

    events = events,

    default_get_geometry = default_get_geometry,
    default_set_geometry = default_set_geometry,

    contains_point = contains_point,

    geometry_to_clip_area = geometry_to_clip_area,
}
