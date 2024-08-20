
local lgi = require("lgi")

local tstation = require("tstation")

local tt_tracker = require("terra.tools.tracker")

local t_element = require("terra.element")

local to_border = require("terra.oak.border")
local to_shape = require("terra.oak.shape")
-- local o_i_unveil = require("oak.internal.unveil") -- TODO: remove this
local to_source = require("terra.oak.source")

-- lua way of freeing a pattern surface
local function finish_pattern_surface(pattern)
    local status, s = pattern:get_surface()
    if status == "SUCCESS" then
        s:finish()
    end
end


-- the action of "processing" is a procedure wherein the parent and the 
-- geometry of the given branch is set, and with that information, the 
-- parent and geometry of each one of the subchildren is recursively 
-- recalculated and applied
local function element_recursively_process(element, abs_x, abs_y, width, height)

    -- TODO: this shouldn't be here, but will do the job for now
    element.oak_private.needs_redraw = false

    -- print("recursively processing element:", element)
    element:set_geometry(abs_x, abs_y, width, height)
    -- print(abs_x, abs_y, width, height)
    -- unveil.dump(element._private.geometry)

    -- the element doesn't have a way to relayout its children
    if element.oak_geometrize_children == nil then return end

    -- if it does, make it relayout its children
    local geometrized_children = element:oak_geometrize_children(width, height) -- TODO: for performance purposes, dont return a table here.

    -- unveil.dump(geometrized_children, {
    --     ignore_fields = {
    --         model = true,
    --         parent = true,
    --         root = true,
    --     }
    -- })

    -- the element has no children
    if geometrized_children == nil then return end

    for _, child_data in ipairs(geometrized_children) do
        element_recursively_process(
            child_data.element, -- the child itself
            child_data.x + abs_x,
            child_data.y + abs_y,
            child_data.width,
            child_data.height
        )
    end
end

local function element_recursively_draw_on_context(element, cr)

    local geometry = element.geometry

    -- print("IN RECURSIVE DRAW")
    -- o_i_unveil.dump(element, {
    --     ignore_fields = {
    --         model = true,
    --         parent = true,
    --         root = true,
    --     }
    -- })

    local draw_func = element.oak_draw
    -- TODO: I don't think I need `before_draw_children` and 
    -- `after_draw_children` anymore.
    local before_draw_children = element.before_draw_children
    local after_draw_children = element.after_draw_children

    local element_x = geometry.x
    local element_y = geometry.y
    local element_x_floor, element_x_fractional_part = math.modf(element_x)
    local element_y_floor, element_y_fractional_part = math.modf(element_y)
    local element_width = geometry.width
    local element_height = geometry.height

    -- TODO: for some reason this cr:save() fixes a bug where if an element
    -- has opacity ~= 1, the subsequent elements don't get drawn anymore.
    -- I think I'm going to rewrite the whole drawing function
    cr:save()
    -- if an element asks for transparency, push all drawing to a temporary 
    -- surface
    if element.opacity ~= nil and element.opacity < 1 then
        cr:push_group()
    end

    if draw_func ~= nil then
        cr:save()

        -- unveil.dump(geometry)

        -- print("element_floor: ", element_x_floor, element_y_floor)
        -- go to where the element's geometry says we should draw
        cr:translate(element_x_floor, element_y_floor)
        cr:rectangle(
            0,
            0,
            math.ceil(element_width + element_x_fractional_part + 1),
            math.ceil(element_height + element_y_fractional_part + 1)
        )
        cr:clip()

        -- check if we have an empty clip first. no reason to draw if it won't be seen
        local clip_x, clip_y, clip_w, clip_h = cr:clip_extents()
        -- print("CLIP EXTENTS: ", clip_x, clip_y, clip_w, clip_h)
        if clip_x ~= clip_w and clip_y ~= clip_h then
            cr:translate(element_x_fractional_part, element_y_fractional_part)
            draw_func(element, cr, element_width, element_height)
        else
            -- print("CANT DRAW", clip_x, clip_y, clip_w, clip_h)
        end

        cr:restore()
    end

    -- TODO: document "before_draw_children" and "after_draw_children" properly.
    cr:translate(element_x, element_y)
    if before_draw_children ~= nil then 
        before_draw_children(element, cr, element_width, element_height)
    end
    cr:translate(-element_x, -element_y)

    if element.oak_children_iter ~= nil then
        for _, child in element:oak_children_iter() do
            element_recursively_draw_on_context(child, cr)
        end
    end

    cr:translate(element_x, element_y)
    if after_draw_children ~= nil then
        after_draw_children(element, cr, element_width, element_height)
    end

    -- pop the surface pushed above and paint it, but with the requested amount 
    -- of transparency
    if element.opacity ~= nil and element.opacity < 1 then
        local drawn_element = cr:pop_group()

        cr:set_operator(lgi.cairo.Operator.OVER)
        cr:set_source(drawn_element)
        cr:paint_with_alpha(element.opacity)

        -- free the surface now
        local status, surf = drawn_element:get_surface()
        if status == "SUCCESS" then
            surf:finish()
        end

    end

    cr:translate(-element_x, -element_y)

    cr:restore()

    assert(cr.status == "SUCCESS", "Cairo context entered error state: " .. cr.status)
end

-- TODO: make this accept a "storage_table" parameter instead of returning a table
-- returns a contiguous array of elements under the mouse, in progressive 
-- order from "bottom-most" to "top-most".
local function element_recursively_get_elements_under_point(element, point_x, point_y)

    local function _dig(acc, elem, x, y)
        if t_element.contains_point(elem, x, y) then
            table.insert(acc, elem)
        end
        if elem.oak_children_iter ~= nil then -- not a branch
            for _, child in elem:oak_children_iter() do
                _dig(acc, child, x, y)
            end
        end
        return acc
    end

    return _dig({}, element, point_x, point_y)
end

-- TODO: make this accept a "storage_table" parameter instead of returning a table
-- an element can have a property like "mouse_input_stop = { MouseMove = true }".
-- if it does, we go through all elements under the mouse, from
-- last ("highest" element), to first ("lowest" element), and when an element
-- has a property like this, all the children under this element don't get
-- the mouse event of that type
local function element_get_approved_mouse_hit_elements(element, event_type, x, y)

    -- TODO: make this not return a table here. For performance.
    local approved_elements = {} 
    local elements_under_mouse = element_recursively_get_elements_under_point(
        element,
        x,
        y
    )

    for i=#elements_under_mouse, 1, -1 do
        local elem = elements_under_mouse[i]
        table.insert(approved_elements, elem)
        if elem.mouse_input_stop ~= nil -- TODO: document this properly
            and elem.mouse_input_stop[event_type] == true
        then
            return approved_elements
        end
    end
    return approved_elements
end

-- local function element_populate_mouse_tables(
--     element, event_type, x, y,
--     tracker,
-- )
--     local elements_under_point = element_get_approved_mouse_hit_elements(element, event_type, x, y)
--     for _, elem in ipairs(elements_under_point) do
--         tt_tracker.track(tracker, elem)
--     end
-- end


return {
    -- element drawing tools
    element_recursively_draw_on_context = element_recursively_draw_on_context,
    element_recursively_process = element_recursively_process,

    -- element mouse tools
    element_recursively_get_elements_under_point = element_recursively_get_elements_under_point,
    element_get_approved_mouse_hit_elements = element_get_approved_mouse_hit_elements,

    -- other, internal tools
    finish_pattern_surface = finish_pattern_surface,
}


