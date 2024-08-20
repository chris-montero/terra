
local lgi = require("lgi")

local tstation = require("tstation")

local tt_tracker = require("terra.tools.tracker")

local t_element = require("terra.element")

local to_border = require("terra.oak.border")
local to_shape = require("terra.oak.shape")
local to_source = require("terra.oak.source")

local function mark_redraw(element)
    local root = element.scope.root
    if root == nil then return end -- not attached
    if element.oak_private.needs_redraw == true then return end -- already marked
    element.oak_private.needs_redraw = true
    root.nr_of_elements_that_need_redraw = root.nr_of_elements_that_need_redraw + 1
end

local function mark_dont_redraw(element)
    local root = element.scope.root
    if root == nil then return end -- not attached
    if element.oak_private.needs_redraw == false then return end -- already not marked
    element.oak_private.needs_redraw = false
    root.nr_of_elements_that_need_redraw = root.nr_of_elements_that_need_redraw - 1
end

local function default_oak_prop_set(element, key, value)
    rawset(element, key, value)
    mark_redraw(element)
end

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

-- TODO: maybe make this also work on unattached branches
local function help_set_child(branch, child)
    mark_redraw(branch)
    child:oak_handle_attach_to_parent_element(
        branch, 
        branch.scope.root, 
        branch.scope.window, 
        branch.scope.app
    )
end

-- TODO: maybe make this also work on unattached branches
local function help_remove_child(branch, child)
    mark_redraw(branch)
    child:oak_handle_detach_from_parent_element(
        branch, 
        branch.scope.root, 
        branch.scope.window, 
        branch.scope.app
    )
end

local function custom_table_insert(branch, n, elem)

    -- make this work like the standard table.insert
    if elem == nil then
        elem = n
        n = #branch + 1
    end

    -- only let users append at the most. Gaps between children are not supported
    if n > #branch + 1 then
        n = #branch + 1 
    end

    -- shift all elements up
    for i=#branch, n, -1 do
        local existing_elem = branch[i]
        local new_index = i + 1
        branch.oak_private.child_id_to_index[existing_elem.oak_private.id] = new_index
        branch[new_index] = branch[i]
    end

    -- finally, insert the element
    branch.oak_private.child_id_to_index[elem.oak_private.id] = n
    branch[n] = elem
end

local function custom_table_remove(branch, n)

    local removed = nil
    local full_branch_l = #branch
    if n == nil then
        n = #branch
    end

    local target_elem = branch[n]
    if target_elem == nil then return removed end

    -- remove the element
    removed = branch[n]
    branch.oak_private.child_id_to_index[target_elem.oak_private.id] = nil
    branch[n] = nil

    -- shift everything down
    for i=n+1, full_branch_l do
        local existing_elem = branch[i]
        local new_index = i-1
        branch.oak_private.child_id_to_index[existing_elem.oak_private.id] = new_index
        branch[new_index] = branch[i]
    end

    return removed
end

local function insert_child_n(branch, n, elem)
    if elem == nil then
        elem = n
        n = #branch + 1
    end
    custom_table_insert(branch, n, elem)
    help_set_child(branch, elem)
end

local function remove_child_n(branch, n)
    local removed = custom_table_remove(branch, n)
    if removed == nil then return end
    help_remove_child(branch, removed)
end

local function set_child_n(branch, n, child)
    if branch[n] == child then return end -- nothing changed
    -- dont let users put gaps between children
    if n > #branch+1 then n = #branch + 1 end 
    local old_child = branch[n]
    if old_child == nil then
        if child == nil then -- nothing to do
            return
        else -- set new
            branch[n] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = n
            help_set_child(branch, child)
        end
    else
        if child == nil then -- remove old
            local removed = remove_child_n(branch, n) -- dont leave gaps
            if removed ~= nil then
                help_remove_child(branch, removed)
            end
        else -- replace old with new
            help_remove_child(branch, old_child)
            help_set_child(branch, child)
            branch[n] = child
            branch.oak_private.child_id_to_index[old_child.oak_private.id] = nil
            branch.oak_private.child_id_to_index[child.oak_private.id] = n
        end
    end
end

local function _set_prop_child_common(branch, str_key, child)

    if branch[str_key] == child then return end -- nothing changed

    if branch[str_key] == nil then
        if child == nil then -- nothing to do
            return
        else
            branch[str_key] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = str_key
            help_set_child(branch, child)
        end
    else
        -- remove the old one
        local old_child = branch[str_key]
        branch.oak_private.child_id_to_index[old_child.oak_private.id] = nil
        help_remove_child(branch, old_child)
        if child == nil then -- set new child as nil
            branch[str_key] = nil
        else -- set new child
            branch[str_key] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = str_key
            help_set_child(branch, child)
        end
    end
end

local function set_bg(branch, new_bg)
    _set_prop_child_common(branch, "bg", new_bg)
end

local function set_shadow(branch, new_shadow)
    _set_prop_child_common(branch, "shadow", new_shadow)
end

-- NOTE: this only works for already-attached elements
local function element_remove(element)
    local parent = element.scope.parent
    if parent == nil then return end -- not attached
    local element_key = parent.oak_private.child_id_to_index[element.oak_private.id]
    if element_key == nil then return end -- should never happen
    if element_key == "bg" then
        set_bg(parent, nil)
    elseif element_key == "shadow" then
        set_shadow(parent, nil)
    else
        remove_element_n(parent, element_index)
    end
end

return {
    -- element drawing tools
    element_recursively_draw_on_context = element_recursively_draw_on_context,
    element_recursively_process = element_recursively_process,

    -- element mouse tools
    element_recursively_get_elements_under_point = element_recursively_get_elements_under_point,
    element_get_approved_mouse_hit_elements = element_get_approved_mouse_hit_elements,

    -- other, internal tools
    finish_pattern_surface = finish_pattern_surface,

    -- element tools
    mark_redraw = mark_redraw,
    mark_dont_redraw = mark_dont_redraw,
    default_oak_prop_set = default_oak_prop_set,

    -- branch child updating tools
    set_bg = set_bg,
    set_shadow = set_shadow,
    set_child_n = set_child_n,
    insert_child_n = insert_child_n,
    remove_child_n = remove_child_n,
    element_remove = element_remove,
}


