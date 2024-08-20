
local lgi = require("lgi")
local tstation = require("tstation")

local tt_table = require("terra.tools.table")
local tt_tracker = require("terra.tools.tracker")

local t_i_unveil = require("terra.internal.unveil")
local t_i_application = require("terra.internal.application")

local t_sigtools = require("terra.sigtools")

local t_element = require("terra.element")

local toe_internal = require("terra.oak.elements.internal")

local toeb_internal = require("terra.oak.elements.branches.internal")
local toeb_branch = require("terra.oak.elements.branches.branch")
local toeb_el = require("terra.oak.elements.branches.el")

-- TODO: document what interface a table must satisfy in order to be a proper <terra.root>
-- * get_geometry(self)
-- * set_geometry(self, x, y, width, height)
-- * draw(self, cr, width, height)
-- * handle_parent_window_destroy_event(root)
-- * handle_mouse_click_event(root, is_press, button, modifiers, x, y)
-- * handle_mouse_enter_event(root, button, modifiers, x, y)
-- * handle_mouse_leave_event(root, button, modifiers, x, y)
-- * handle_mouse_motion_event(root, modifiers, x, y)
-- * handle_attach_to_window(root, window, app)
-- * handle_detach_from_window(root, window, app)

-- NOTE: for now, we just use simple method calls to make this work. Later,
-- this might change to using signals.

-- TODO: change the names of all relevant methods to denote which interface they fulfill
-- For example: 
-- * the root should have a `terra_root_draw(self)` method to denote it fulfills 
-- part of the interface to be a <terra.root>.
-- * the root should give the user the option to set a `oak_draw(self, cr, width, height)`
-- method, in case the user wants to draw directly on the root.
-- If these two methods were both simply called `draw` it wouldn't work.


local function handle_parent_window_destroy_event(root)
    -- TODO: implement
end
local function handle_parent_window_became_visible(root)
end
local function handle_parent_window_became_invisible(root)
end
local function handle_mouse_click_event(root, is_press, button, modifiers, x, y)

    tstation.emit(root.station, 
        t_element.events.MouseClickEvent, -- event type
        is_press,
        button,
        modifiers,
        -- TODO: make this work with relative coords after letting the root 
        -- set x, y, width, height.
        x,
        y
    )

    local hit_elements = toe_internal.element_get_approved_mouse_hit_elements(
        root,
        t_element.events.MouseClickEvent,
        x,
        y
    )

    for _, child in ipairs(hit_elements) do
        local geom = child:get_geometry()
        tstation.emit(child.station, 
            t_element.events.MouseClickEvent, -- event type
            is_press,
            button,
            modifiers,
            -- translate the coordinates so the child gets relative coordinates
            -- TODO: test this
            math.floor(x - geom.x),
            math.floor(y - geom.y)
        )
    end
end

local function handle_mouse_enter_event(root, button, modifiers, x, y)

    -- -- emit it first on the root itself
    -- tstation.emit(root.station, t_element.events.MouseEnterEvent, button, modifiers, x, y)

    -- now, get all children that should be notified of the enter event
    -- local hit_children = toe_internal.element_get_approved_mouse_hit_elements(
    --     root,
    --     t_element.events.MouseEnterEvent,
    --     x,
    --     y
    -- )

    -- update the new elements under the mouse, and emit the signal on them too
    -- for k, elem in ipairs(hit_children) do
    --     root.oak_private.elements_under_mouse_last_list[k] = elem
    --     root.oak_private.elements_under_mouse_last_mapping[elem.oak_private.id] = elem
    --
    --     tstation.emit(elem.station, button, modifiers, x, y)
    -- end

    tt_tracker.reset(root.oak_private.tracker_last)
    tt_tracker.reset(root.oak_private.tracker_now)

    local hit_elements = toe_internal.element_get_approved_mouse_hit_elements(
        root,
        t_element.events.MouseEnterEvent,
        x,
        y
    )
    for _, elem in ipairs(hit_elements) do
        tt_tracker.track(root.oak_private.tracker_now, elem)

        local elem_geom = elem:get_geometry()
        tstation.emit(elem.station, 
            t_element.events.MouseEnterEvent, -- event type
            -- translate the coordinates so the child gets relative coordinates
            -- TODO: test this
            modifiers,
            math.floor(x - elem_geom.x),
            math.floor(y - elem_geom.y)
        )
    end
end

local function handle_mouse_leave_event(root, button, modifiers, x, y)

    for elem in tt_tracker.iter(root.oak_private.tracker_now) do
        local elem_geom = elem:get_geometry()
        tstation.emit(elem.station, 
            t_element.events.MouseLeaveEvent, -- event type
            modifiers,
            math.floor(x - elem_geom.x),
            math.floor(y - elem_geom.y)
        )
    end
    tt_tracker.reset(root.oak_private.tracker_last)
    tt_tracker.reset(root.oak_private.tracker_now)

    -- for _, elem in ipairs(root.oak_private.elements_under_mouse_last_list) do
    --     tstation.emit(elem.station, 
    --         t_element.events.MouseLeaveEvent, -- event type
    --         x,
    --         y
    --     )
    -- end

    -- for id, elem in pairs(root.oak_private.elements_under_mouse_last_mapping) do
    --     root.oak_private.elements_under_mouse_last_mapping[id] = nil
    --     local elem_geom = elem:get_geometry()
    --     tstation.emit(elem.station, 
    --         t_element.events.MouseLeaveEvent, -- event type
    --         math.floor(x - elem_geom.x),
    --         math.floor(y - elem_geom.y)
    --     )
    -- end
end

local function handle_mouse_motion_event(root, modifiers, x, y)

    -- tstation.emit(root.station, 
    --     t_element.events.MouseMotionEvent, -- event type
    --     -- TODO: make this work with relative coords after letting the root 
    --     -- set x, y, width, height.
    --     modifiers,
    --     x,
    --     y
    -- )

    -- update the trackers: 
    -- * discard the "tracker_last" data
    -- * move the "tracker_now" data to "tracker_last"
    -- * discard the "tracker_now" data
    -- * populate "tracker_now" with correct information
    tt_tracker.reset(root.oak_private.tracker_last)
    for elem in tt_tracker.iter(root.oak_private.tracker_now) do
        tt_tracker.track(root.oak_private.tracker_last, elem)
    end
    tt_tracker.reset(root.oak_private.tracker_now)

    local hit_elements = toe_internal.element_get_approved_mouse_hit_elements(
        root,
        t_element.events.MouseMotionEvent,
        x,
        y
    )
    for _, elem in ipairs(hit_elements) do
        tt_tracker.track(root.oak_private.tracker_now, elem)
    end

    -- the trackers are updated. now, emit all the signals.

    -- if there's an element in the new tracker that does not exist in 
    -- the old tracker, emit a MouseEnterEvent.
    for elem in tt_tracker.iter(root.oak_private.tracker_now) do
        if tt_tracker.contains(root.oak_private.tracker_last, elem) == false then
            local elem_geom = elem:get_geometry()
            tstation.emit(elem.station, 
                t_element.events.MouseEnterEvent, -- event type
                -- translate the coordinates so the child gets relative coordinates
                -- TODO: test this
                modifiers,
                math.floor(x - elem_geom.x),
                math.floor(y - elem_geom.y)
            )
        end
    end

    -- if there's an element in the old tracker that does not exist in 
    -- the new tracker, emit a MouseLeaveEvent.
    for elem in tt_tracker.iter(root.oak_private.tracker_last) do
        if tt_tracker.contains(root.oak_private.tracker_now, elem) == false then
            local elem_geom = elem:get_geometry()
            tstation.emit(elem.station, 
                t_element.events.MouseLeaveEvent, -- event type
                -- translate the coordinates so the child gets relative coordinates
                -- TODO: test this
                modifiers,
                math.floor(x - elem_geom.x),
                math.floor(y - elem_geom.y)
            )
        end
    end

    -- finally, emit the mouse motion event
    for _, elem in ipairs(hit_elements) do
        local elem_geom = elem:get_geometry()
        tstation.emit(elem.station, 
            t_element.events.MouseMotionEvent, -- event type
            -- translate the coordinates so the child gets relative coordinates
            -- TODO: test this
            modifiers,
            math.floor(x - elem_geom.x),
            math.floor(y - elem_geom.y)
        )
    end

end

local function setup_signals(root, parent_window, parent_app)
    t_sigtools.setup_subscribe_on_object_signals(root, "self", root)
    t_sigtools.setup_subscribe_on_object_signals(parent_window, "window", root)
    t_sigtools.setup_subscribe_on_object_signals(parent_app, "app", root)
end

local function teardown_signals(root, parent_window, parent_app)
    t_sigtools.teardown_subscribe_on_object_signals(root, "self", root)
    t_sigtools.teardown_subscribe_on_object_signals(parent_window, "window", root)
    t_sigtools.teardown_subscribe_on_object_signals(parent_app, "app", root)
end

local function handle_attach_to_window(root, window, app)

    root.scope.self = root
    root.scope.root = root -- we need this in order to make `toe_internal.mark_redraw` work
    root.scope.window = window
    root.scope.app = app

    setup_signals(root, window, app)

    for _, child in root:oak_children_iter() do
        print(root, child)
        -- TODO: implement this properly for all children
        child:oak_handle_attach_to_parent_element(root, root, window, app) -- parent, root, window, app
    end
end

local function handle_detach_from_window(root, window, app)

    root.scope.self = nil
    root.scope.root = nil
    root.scope.window = nil
    root.scope.app = nil

    teardown_signals(root, window, app)

    for _, child in root:oak_children_iter() do
        -- TODO: implement this properly for all children
        child:oak_handle_detach_from_parent_element(root, root, window, app) -- parent, root, window, app
    end
end


-- Just draw everything if anything changed LMAO
-- TODO: in the future, implement a more optimized drawing function
local function draw(root, cr, window_width, window_height)

    -- send out an AnimationEvent signal, if anybody wants to do something
    tstation.emit(root.station, "AnimationEvent", t_i_application.now())

    local root_geom = root:get_geometry()
    if root_geom.width ~= window_width or root_geom.height ~= window_height then
        -- TODO: let the root also position itself according to properties like "valign", "halign", etc.
        root:set_geometry(0, 0, window_width, window_height)
        toe_internal.mark_redraw(root)
    end

    -- if nothing changed, just return
    if root.nr_of_elements_that_need_redraw == 0 then 
        return false -- nothing was drawn
    end

    -- relayout everything and reset which elements need to be redrawn
    local geom = root:get_geometry()
    toe_internal.element_recursively_process(
        root,
        geom.x,
        geom.y,
        geom.width,
        geom.height
    )

    -- reset the clip so we can draw anywhere on the window
    cr:reset_clip()
    -- TODO: clip to only draw within root bounds

    -- draw the background first, so we don't get "solitaire trails" from 
    -- previous drawings if the background is transparent
    cr:save() -- save because we don't want to use this operator for everything.
    -- We use the CLEAR operator to make sure that all previous data
    -- that used to exist in memory where our surface now exists gets cleared.
    -- Otherwise we can get random artifacts and trash in our drawing.
    -- This will also automatically draw transparency if a compositor
    -- is running.
    cr:set_operator(lgi.cairo.Operator.CLEAR)
    cr:paint()
    cr:restore()

    -- draw the whole tree onto the pixmap.
    toe_internal.element_recursively_draw_on_context(root, cr)

    root.nr_of_elements_that_need_redraw = 0

    return true -- something was redrawn
end

local function root_oak_geometrize_children(root, width, height)
    -- root can NOT have a shadow
    if root.bg == nil and #root == 0 then return nil end

    -- TODO: turn this into a single function that sets the geometries 
    -- of its children directly
    return toeb_el.position_children(
        toeb_el.dimensionate_children(root, width, height)
    )
end

local function root_oak_children_iter(root)
    -- root can only have a bg and numerical indexed children

    local co = coroutine.create(function()
        if root.bg ~= nil then
            coroutine.yield("bg", root.bg)
        end

        for i=1, #root do
            coroutine.yield(i, root[i])
        end
    end)

    return function ()
        local is_not_finished, key, val = coroutine.resume(co)
        if is_not_finished then
            return key, val
        else
            return nil, nil
        end
    end
end

local function new(args)

-- TODO: document supported args
-- * 

    local root_defaults = {
        -- used for redraw -- TODO: move this in oak_private
        nr_of_elements_that_need_redraw = 0,

        oak_private = {
            -- use an empty function for ID. TODO: check if this is efficient
            id = function() end,

            -- necessary for branches, which the root is
            child_id_to_index = {}, 

            -- used for knowing each frame if we should draw at all.
            -- Saves up CPU time when nothing is happening.
            needs_redraw = false,

            -- used for emitting mouse enter and leave events
            tracker_last = tt_tracker.new(),
            tracker_now = tt_tracker.new(),
        },
        scope = {
            -- self : <self_ref>
            -- window : <window_ref>
            -- app : <app_ref>
        },

        -- event handling interface. needed to be a <terra.window>.tree
        handle_parent_window_destroy_event = handle_parent_window_destroy_event,
        handle_mouse_click_event = handle_mouse_click_event,
        handle_mouse_enter_event = handle_mouse_enter_event,
        handle_mouse_leave_event = handle_mouse_leave_event,
        handle_mouse_motion_event = handle_mouse_motion_event,

        -- other auxiliary methods. needed to be a <terra.window>.tree
        handle_attach_to_window = handle_attach_to_window,
        handle_detach_from_window = handle_detach_from_window,
        draw = draw,

        -- the interface to be an oak branch
        oak_geometrize_children = root_oak_geometrize_children,
        oak_children_iter = root_oak_children_iter,

        -- TODO: make it so that these fields dont HAVE to be set, but instead
        -- the user can choose which ones to define
        subscribe_on_self = {},
        subscribe_on_window = {},
        subscribe_on_app = {},

        -- transform-related property setters
        set_offset_x = set_offset_x,
        set_offset_y = set_offset_y,
        -- TODO: implement scale_x, scale_y, rotate, origin

        -- drawing related property setters
        set_oak_draw = set_oak_draw,
        set_opacity = set_opacity,

        set_bg = toeb_branch.set_bg,
        set_child_n = toeb_branch.set_child_n,
        insert_child_n = toeb_branch.insert_child_n,
        remove_child_n = toeb_branch.remove_child_n,
        set_valign = set_valign,
        set_halign = set_halign,
    }

    return tt_table.crush(t_element.new(), root_defaults, args)
end

return {
    new = new,
    draw = draw,

    setup_signals = setup_signals,
    teardown_signals = teardown_signals,

    oak_geometrize_children = root_oak_geometrize_children,
    oak_children_iter = root_oak_children_iter,

    handle_attach_to_window = handle_attach_to_window,
    handle_detach_from_window = handle_detach_from_window,
    handle_parent_window_destroy_event = handle_parent_window_destroy_event,
    handle_mouse_click_event = handle_mouse_click_event,
    handle_mouse_enter_event = handle_mouse_enter_event,
    handle_mouse_leave_event = handle_mouse_leave_event,
    handle_mouse_motion_event = handle_mouse_motion_event,

}

