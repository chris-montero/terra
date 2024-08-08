
local function needs_relayout(element)
    return element._oak_private.needs_relayout
end

local function needs_redraw(element)
    return element._oak_private.needs_redraw
end

local function mark_relayout(element)

    -- if this element is not attached to a root, don't mark it because all 
    -- freshly attached elements automatically get relayouted and redrawn.
    local root = element.scope.root
    if root == nil then return end 

    -- is the element already marked?
    if element._oak_private.needs_relayout then return end

    root.nr_of_elements_that_need_relayout = root.nr_of_elements_that_need_relayout + 1

    element._oak_private.needs_relayout = true
end

local function mark_redraw(element)

    -- if this element is not attached to a root, don't mark it because all 
    -- freshly attached elements automatically get relayouted and redrawn.
    local root = element.scope.root
    if root == nil then return end 

    -- is the element already marked?
    if element._oak_private.needs_redraw then return end

    root.nr_of_elements_that_need_redraw = root.nr_of_elements_that_need_redraw + 1

    element._oak_private.needs_redraw = true
end

local function mark_dont_relayout(element)

    local root = element.scope.root
    if root == nil then return end

    if element._oak_private.needs_relayout == false then return end

    root.nr_of_elements_that_need_relayout = root.nr_of_elements_that_need_relayout - 1

    element._oak_private.needs_relayout = false
end

local function mark_dont_redraw(element)

    local root = element.scope.root
    if root == nil then return end

    if element._oak_private.needs_redraw == false then return end

    root.nr_of_elements_that_need_redraw = root.nr_of_elements_that_need_redraw - 1

    element._oak_private.needs_redraw = false
end

-- local function element_mark_redraw_all_subchildren(element)
--     -- TODO: make the "get_children" method actually be an iterator instead 
--     -- of a method that returns a table so that I can avoid some of the 
--     -- mumbo jumbo below. (and hopefully it will also be faster)
--     element_mark_redraw(element)
--     if element.oak_get_children == nil then return end -- not a branch
--     local children = element:oak_get_children()
--     if children == nil then return end -- no children
--     for _, c in ipairs(children) do
--         element_mark_redraw_all_subchildren(c)
--     end
-- end

-- -- returns a list of the fewest elements that need a relayout
-- -- for example: if 'b' is the child of 'a', and they're both marked as requiring
-- -- a relayout, only { a } will be returned because 'b' will automatically be
-- -- relayouted when 'a' will be, since all children of a relayoued element are
-- -- automatically relayouted
-- local function get_least_elements_to_relayout(element)
--
--     local function dig(storage, current_element)
--
--         if current_element.oak_get_children == nil then return end
--         local children = current_element:oak_get_children()
--         for _, c in ipairs(children) do
--
--             if element_needs_relayout(c) then
--                 table.insert(storage, c)
--             else
--                 dig(storage, c)
--             end
--
--         end
--
--     end
--
--     local elements_needing_relayout = {}
--     dig(elements_needing_relayout, element)
--     return elements_needing_relayout
-- end
--
-- -- traverses the whole tree and returns a list of all elements that need to
-- -- be redrawn
-- local function get_all_elements_to_redraw(element)
--
--     local function dig(storage, current_element)
--
--         if current_element.oak_get_children == nil then return end
--         local children = current_element:oak_get_children()
--         for _, c in ipairs(children) do
--             if element_needs_redraw(c) then
--                 table.insert(storage, c)
--                 dig(storage, c)
--             end
--         end
--     end
--
--     local elements_needing_redraw = {}
--     dig(elements_needing_redraw, element)
--     return elements_needing_redraw
-- end

-- TODO: TEST
-- TODO: try to turn this an iterator and not create tables anymore.
local function element_get_children_to_relayout_and_redraw(element)

    local function dig(
        current,
        least_relayout_storage, -- the "least" elements that need to be relayouted
        all_relayout_storage, -- all elements that were marked to be relayouted
        redraw_storage, -- all elements that need to be redrawn
        should_still_check_for_relayout,
        should_redraw_from_here_on
    )
        if element_needs_relayout(current) then
            should_redraw_from_here_on = true
            if should_still_check_for_relayout then
                table.insert(least_relayout_storage, current)
                should_still_check_for_relayout = false
            end
            table.insert(all_relayout_storage, current)
        end

        if should_redraw_from_here_on then
            table.insert(redraw_storage, current)
        else
            if element_needs_redraw(current) then
                table.insert(redraw_storage, current)
            end
        end

        if current.oak_get_children == nil then return end
        local children = current:oak_get_children()
        for _, c in ipairs(children) do
            dig(
                c,
                least_relayout_storage,
                all_relayout_storage,
                redraw_storage,
                should_still_check_for_relayout,
                should_redraw_from_here_on
            )
        end
    end

    local least_elements_to_relayout = {}
    local all_elements_to_relayout = {}
    local elements_to_redraw = {}
    dig(
        element,
        least_elements_to_relayout,
        all_elements_to_relayout,
        elements_to_redraw,
        true,
        false
    )

    return least_elements_to_relayout, all_elements_to_relayout, elements_to_redraw
end

-- TODO: either make this work, or add something like a "shape" 
-- property to all elements.
local function apply_clip_shape(branch, cr, width, height)

    local clip_shape = branch.clip_shape
    if clip_shape ~= nil then
        clip_shape(branch, cr, width, height)
        return
    end

    local bg = branch.bg
    if bg == nil then
        return
    end

    local border_radius = bg.border_radius or 0
    if border_radius == 0 then
        return
    end

    if branch.clip_to_background == true then

        local border_width = bg.border_width or 0
        cr:translate(border_width, border_width)
        to_shape.rounded_rectangle(
            cr,
            width - (border_width * 2),
            height - (border_width * 2),
            border_radius
        )

    end

end

