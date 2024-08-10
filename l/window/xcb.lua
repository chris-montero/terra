
local lgi = require("lgi")
local tstation = require("tstation")

local t_i_spixmap = require("terra.internal.spixmap")
local t_i_scairo = require("terra.internal.scairo")
local t_i_swin = require("terra.internal.swin")
local t_i_unveil = require("terra.internal.unveil")

local t_time = require("terra.time")
local t_sigtools = require("terra.sigtools")
local t_orchard = require("terra.orchard")
local t_element = require("terra.element")

local tt_table = require("terra.tools.table")

local tw_internal = require("terra.window.internal")

local events = {
    WindowFocusEvent = "WindowFocusEvent",
    WindowUnfocusEvent = "WindowUnfocusEvent",
}

-- * ".wants_titlebar" : <boolean> a window can specify if it wants a titlebar

-- TODO: make it so that the user has the option to either handle platform specific events directly or abstract them away automatically

-- TODO: document what interface a table must satisfy in order to be a proper <terra.window>

local function _window_drawing_context_destroy(window)

    -- first, destroy what needs to be destroyed.
    -- TODO: can I use cairo_surface_create_similar for better performance?
    window.lgi_cairo_surf:finish()
    t_i_spixmap.destroy(window.scope.app.terra_data, window.pixmap_id)
    t_i_scairo.destroy(window.cairo_surf_ptr) -- we don't need 'window.scope.app.terra_data' for this

    -- then unset them, and the gc should take care of the rest.
    window.pixmap_id = nil
    window.cairo_surf_ptr = nil
    window.lgi_cairo_surf = nil
    window.cr = nil
end

local function _window_drawing_context_setup(window, width, height)
    local terra_data = window.scope.app.terra_data

    -- create all the stuff
    local pixmap_id = t_i_spixmap.create(terra_data, width, height)
    local cairo_surf_ptr = t_i_scairo.create_from_pixmap(terra_data, pixmap_id, width, height)
    local lgi_cairo_surf = lgi.cairo.Surface(cairo_surf_ptr, true)
    local cr = lgi.cairo.Context(lgi_cairo_surf)

    -- set all the context
    window.pixmap_id = pixmap_id
    window.cairo_surf_ptr = cairo_surf_ptr
    window.lgi_cairo_surf = lgi_cairo_surf
    window.cr = cr

    -- and set the new pixmap sizes; TODO: this shouldn't be exposed on the lua side.
    window.pixmap_width = width
    window.pixmap_height = height 
end



-- TODO: there should be a way for the user to know if his request was granted/denied
local function request_raise(window)
    t_i_swin.map_request(window.scope.app.terra_data, window.window_id)
end

local function hide(window)
    t_i_swin.unmap(window.scope.app.terra_data, window.window_id)
end

local function destroy(window)
    t_i_swin.destroy(window.window_id)
end

local function request_geometry_change(window, x, y, width, height)
    local window_geom = window:get_geometry()
    if window_geom.x == x and window_geom.y == y and window_geom.width == width and window_geom.height == height then return end

    t_i_swin.set_geometry_request(window.window_id, x, y, width, height)
end

local function draw(window)

    local tree = window.tree
    if tree == nil then return end

    -- if the window is not visible, don't draw.
    if window.visibility ~= tw_internal.visibility.RAISED_AND_SHOWING then 
        print("NO NEED TO DRAW BECAUSE NOT SHOWING")
        return
    end

    -- if the geometry of the window changed since last time, we need a new 
    -- context for drawing.
    local window_geom = window:get_geometry()
    if window_geom.width ~= window.pixmap_width 
        or window_geom.height ~= window.pixmap_height 
    then
        _window_drawing_context_destroy(window)
        _window_drawing_context_setup(window, window_geom.width, window_geom.height)
    end

    -- let the tree do its drawing
    local something_was_drawn = tree:draw(window.cr, window_geom.width, window_geom.height)
    if something_was_drawn == false then return end

    -- finally, copy the drawing from the pixmap to the window
    t_i_spixmap.draw_portion_to_window(
        window.scope.app.terra_data,
        window.pixmap_id,
        window.window_id,
        -- TODO: since we never need to draw to other coordinates, it 
        -- probably makes most sense to just remove these geometry 
        -- numbers from here.
        0,
        0,
        window.pixmap_width,
        window.pixmap_height
    )

    -- print("!!!!!!!!!!!!!!DRAWN TERRA WINDOW")
end

-------------------
-- event handlers
-------------------

-- this gets called when the geometry of a window changes
local function handle_configure_notify_event(window, x, y, width, height)

    window:set_geometry(x, y, width, height)

    -- TODO: make it so that in a list of configure notify events, only the 
    -- last one is processed. (from the C side)

    -- NOTE: the contained tree, if any, will be notified of the change in 
    -- the `draw` function
    if window.max_fps == nil then
        window:draw() -- if no fps limit, draw immediately
    end
end

local function handle_mouse_click_event(window, is_press, button, modifiers, x, y)

    tstation.emit(window.station, t_element.events.MouseClickEvent, is_press, button, modifiers, x, y)

    local tree = window.tree
    if tree ~= nil then 
        local tree_geom = tree:get_geometry()
        if x < tree_geom.width and y < tree_geom.height then 
            tree:handle_mouse_click_event(is_press, button, modifiers, x, y)
        end
    end

    if window.max_fps == nil then
        window:draw()
    end
end

local function handle_create_event(window) -- TODO: maybe add proper support for X windows
    -- this can only happen if someone creates a window with us as the parent.
    -- this is currently not supported, so we do nothing.
end

local function handle_destroy_event(window) -- TODO: maybe add proper support for X windows
    -- TODO: maybe rename this ".parent_app"
    local app = window.scope.app

    -- teardown signals
    tw_internal.teardown_signals(window, app)

    -- stop tracking this window
    t_orchard.remove_window_by_id(app.orchard, window.window_id)

    -- de-allocate everything
    _window_drawing_context_destroy(window)

    -- let the tree know about this
    local tree = window.tree
    if tree == nil then return end
    tree:handle_parent_window_destroy_event()
end

local function handle_mouse_enter_event(window, button, modifiers, x, y)

    tstation.emit(window.station, t_element.events.MouseEnterEvent, button, modifiers, x, y)

    local tree = window.tree
    if tree ~= nil then
        local tree_geom = tree:get_geometry()
        if x < tree_geom.width and y < tree_geom.height then 
            tree:handle_mouse_enter_event(button, modifiers, x, y)
        end -- TODO: should we allow trees to specify their x y coords?
    end

    if window.max_fps == nil then
        window:draw()
    end
end

local function handle_expose_event(window, x, y, width, height, count)
    window:draw()
end

local function handle_focus_in_event(window)
    window.focused = true -- TODO: do we even need this? The user can start tracking this if he wants.
    tstation.emit(window.station, events.WindowFocusEvent)
end

local function handle_focus_out_event(window)
    window.focused = false -- TODO: do we even need this? The user can start tracking this if he wants.
    tstation.emit(window.station, events.WindowUnfocusEvent)
end

local function handle_key_event(window, is_press, key, modifiers)
    -- TODO: set keybindings on windows directly
end

local function handle_mouse_leave_event(window, button, modifiers, x, y)

    tstation.emit(window.station, t_element.events.MouseLeaveEvent, button, modifiers, x, y) -- TODO: maybe it should be up to the tree to emit this event on the window

    local tree = window.tree
    if tree ~= nil then 
        local tree_geom = tree:get_geometry()

        -- TODO: should we allow trees to specify their x y coords?
        if x < tree_geom.width and y < tree_geom.height then 
            tree:handle_mouse_leave_event(button, modifiers, x, y)
        end
    end

    if window.max_fps == nil then
        window:draw()
    end
end

local function handle_mouse_motion_event(window, modifiers, x, y)

    -- TODO: should it be up to the child tree if the window gets mouse events?
    tstation.emit(window.station, t_element.events.MouseMotionEvent, modifiers, x, y)

    local tree = window.tree
    if tree ~= nil then 

        -- TODO: should we allow trees to specify their x y coords?
        local tree_geom = tree:get_geometry()
        if x < tree_geom.width and y < tree_geom.height then 
            tree:handle_mouse_motion_event(modifiers, x, y)
        end
    end

    if window.max_fps == nil then
        window:draw()
    end
end

local function handle_map_event(window)
    window.visibility = tw_internal.visibility.RAISED
    -- local tree = window.tree
    -- if tree == nil then return end
end

local function handle_map_request(window, window_id)
    -- this could only happen if we had child windows and one of them 
    -- requested to be mapped. This is currently not supported.
end

local function handle_property_event(window, atom, time, state)
    -- TODO: implement this properly
end

local function handle_reparent_event(window, event_window_id, parent_id, window_id, x, y)
    -- This is currently not supported. TODO: maybe add support
end

local function handle_visibility_event(window, visibility)
    window.visibility = tw_internal.visibility.RAISED_AND_SHOWING

    tstation.emit(window.station, "WindowBecameVisible")

    -- always draw when the window becomes visible. Otherwise it will just be blank.
    window:draw()
end

local function handle_unmap_event(window)
    window.visibility = tw_internal.visibility.HIDDEN
    tstation.emit(window.station, "WindowBecameInvisible")
end

local function handle_frame_event(window, time)
    window:draw()
end


-- we have the user provide the x, y, width, height separately because 
-- they shouldn't operate under the delusion that changing the window.width 
-- would actually change the window width. The user should use 
-- `request_geometry_change` for that.
local function create(app, x, y, width, height, args)

    local xcb_window_defaults = {
        handle_configure_notify_event = handle_configure_notify_event,
        handle_mouse_click_event = handle_mouse_click_event,
        handle_create_event = handle_create_event,
        handle_destroy_event = handle_destroy_event,
        handle_mouse_enter_event = handle_mouse_enter_event,
        handle_expose_event = handle_expose_event,
        handle_focus_in_event = handle_focus_in_event,
        handle_focus_out_event = handle_focus_out_event,
        handle_key_event = handle_key_event,
        handle_mouse_leave_event = handle_mouse_leave_event,
        handle_mouse_motion_event = handle_mouse_motion_event,
        handle_map_event = handle_map_event,
        handle_map_request = handle_map_request,
        handle_property_event = handle_property_event,
        handle_reparent_event = handle_reparent_event,
        handle_visibility_event = handle_visibility_event,
        handle_unmap_event = handle_unmap_event,
        handle_frame_event = handle_frame_event,

        -- by default xcb windows should have titlebars
        wants_titlebar = true,
    }
    local window = tw_internal.common_new(
        app, 
        x, y, width, height,
        tt_table.crush(xcb_window_defaults, args)
    )

    -- then, create a window
    window.window_id = t_i_swin.create(
        app.terra_data,
        x,
        y,
        width,
        height,
        not window.wants_titlebar -- TODO: make this work
    )

    -- setup its drawing context
    _window_drawing_context_setup(window, width, height)

    -- start tracking the window. we need this in order to properly delegate 
    -- events to specific windows
    t_orchard.add_window(window.scope.app.orchard, window)

    return window
end


return {
    create = create,
    destroy = destroy,
    hide = hide,

    request_raise = request_raise,
    request_geometry_change = request_geometry_change,

    set_tree = set_tree,

    handle_configure_notify_event = handle_configure_notify_event,
    handle_mouse_click_event = handle_mouse_click_event,
    handle_create_event = handle_create_event,
    handle_destroy_event = handle_destroy_event,
    handle_mouse_enter_event = handle_mouse_enter_event,
    handle_expose_event = handle_expose_event,
    handle_focus_in_event = handle_focus_in_event,
    handle_focus_out_event = handle_focus_out_event,
    handle_key_event = handle_key_event,
    handle_mouse_leave_event = handle_mouse_leave_event,
    handle_mouse_motion_event = handle_mouse_motion_event,
    handle_map_event = handle_map_event,
    handle_map_request = handle_map_request,
    handle_property_event = handle_property_event,
    handle_reparent_event = handle_reparent_event,
    handle_visibility_event = handle_visibility_event,
    handle_unmap_event = handle_unmap_event,
    handle_frame_event = handle_frame_event,
}

