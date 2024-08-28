
local lgi = require("lgi")
local tstation = require("tstation")

local t_sigtools = require("terra.sigtools")
local t_orchard = require("terra.orchard")
local t_element = require("terra.element")

local tt_table = require("terra.tools.table")

local tpx_spixmap = require("terra.platforms.xcb.spixmap")
local tpx_scairo = require("terra.platforms.xcb.scairo")
local tpx_swin = require("terra.platforms.xcb.swin")

local tpc_window = require("terra.platforms.common.window")

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
    tpx_spixmap.destroy(window.scope.app.xcb_ctx, window.pixmap_id)
    tpx_scairo.destroy(window.cairo_surf_ptr) -- we don't need 'window.scope.app.xcb_ctx' for this

    -- then unset them, and the gc should take care of the rest.
    window.pixmap_id = nil
    window.cairo_surf_ptr = nil
    window.lgi_cairo_surf = nil
    window.cr = nil
end

local function _window_drawing_context_setup(window, width, height)
    local xcb_ctx = window.scope.app.xcb_ctx

    -- create all the stuff
    local pixmap_id = tpx_spixmap.create(xcb_ctx, width, height)
    local cairo_surf_ptr = tpx_scairo.create_from_pixmap(xcb_ctx, pixmap_id, width, height)
    local lgi_cairo_surf = lgi.cairo.Surface(cairo_surf_ptr, true)
    local cr = lgi.cairo.Context(lgi_cairo_surf)

    -- set all the context
    window.pixmap_id = pixmap_id
    window.cairo_surf_ptr = cairo_surf_ptr
    window.lgi_cairo_surf = lgi_cairo_surf
    window.cr = cr
end

local function _window_drawing_context_update(window, width, height)
    local xcb_ctx = window.scope.app.xcb_ctx
    tpx_spixmap.destroy(xcb_ctx, window.pixmap_id)
    window.pixmap_id = tpx_spixmap.create(xcb_ctx, width, height)
    tpx_scairo.set_pixmap(window.cairo_surf_ptr, window.pixmap_id, width, height)
end

-- returns true if the window drew anything, false otherwise
local function draw(window)
    window:reset_frame_timer()

    local tree = window.tree
    if tree == nil then return false end

    -- if the window is not visible, don't draw.
    if window.visibility ~= tpc_window.visibility.RAISED_AND_SHOWING then 
        -- print("NO NEED TO DRAW BECAUSE NOT SHOWING")
        return false
    end

    local window_geom = window:get_geometry()

    -- if the geometry of the window changed since last time, we need a new 
    -- context for drawing.
    if window.width ~= window_geom.width or window.height ~= window_geom.height then
        _window_drawing_context_update(window, window.width, window.height)
    end

    -- if the window geometry changed since last frame, update it
    if
        window.x ~= window_geom.x
        or window.y ~= window_geom.y
        or window.width ~= window_geom.width
        or window.height ~= window_geom.height
    then
        window:set_geometry(window.x, window.y, window.width, window.height)
    end

    -- let the tree do its drawing
    local something_was_drawn = tree:draw(window.cr, window_geom.width, window_geom.height)
    if something_was_drawn == false then 
        return false
    -- else
    --     print("drawn")
    end

    -- finally, copy the drawing from the pixmap to the window
    tpx_spixmap.draw_portion_to_window(
        window.scope.app.xcb_ctx,
        window.pixmap_id,
        window.window_id,
        -- TODO: since we never need to draw to other coordinates, it 
        -- probably makes most sense to just remove these geometry 
        -- numbers from here.
        0,
        0,
        window_geom.width,
        window_geom.height
    )

    return true
end

-------------------
-- event handlers
-------------------

-- this gets called when the geometry of a window changes
local function handle_configure_notify_event(window, x, y, width, height)

    window.x = x
    window.y = y
    window.width = width
    window.height = height

    -- after the window was resized, draw the window again instantly. 
    -- This will also reset the timer.
    window:draw()
end

local function handle_mouse_click_event(window, is_press, button, modifiers, x, y)

    tstation.emit(window.station, t_element.events.MouseClickEvent, is_press, button, modifiers, x, y)

    local tree = window.tree
    if tree ~= nil then 
        tree:handle_mouse_click_event(is_press, button, modifiers, x, y)
    end

    -- if window.max_fps == nil then
    --     window:draw()
    -- end
end

local function handle_create_event(window) -- TODO: maybe add proper support for X windows
    -- this can only happen if someone creates a window with us as the parent.
    -- this is currently not supported, so we do nothing.
end

local function handle_destroy_event(window) -- TODO: maybe add proper support for X windows
    local app = window.scope.app

    -- teardown signals
    tpc_window.teardown_signals(window, app)

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
        tree:handle_mouse_enter_event(button, modifiers, x, y)
    end

    -- if window.max_fps == nil then
    --     window:draw()
    -- end
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
        tree:handle_mouse_leave_event(button, modifiers, x, y)
    end

    -- if window.max_fps == nil then
    --     window:draw()
    -- end
end

local function handle_mouse_motion_event(window, modifiers, x, y)

    -- TODO: should it be up to the child tree if the window gets mouse events?
    tstation.emit(window.station, t_element.events.MouseMotionEvent, modifiers, x, y)

    local tree = window.tree
    if tree ~= nil then 
        tree:handle_mouse_motion_event(modifiers, x, y)
    end

    -- if window.max_fps == nil then
    --     window:draw()
    -- end
end

local function handle_map_event(window)
    window.visibility = tpc_window.visibility.RAISED
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
    window.visibility = tpc_window.visibility.RAISED_AND_SHOWING

    tstation.emit(window.station, "WindowBecameVisible") -- TODO: dont use string directly here

    -- always draw when the window becomes visible. Otherwise it will just be blank.
    window:draw()
end

local function handle_unmap_event(window)
    window.visibility = tpc_window.visibility.HIDDEN
    tstation.emit(window.station, "WindowBecameInvisible") -- TODO: dont use string directly here
end

local function handle_frame_event(window, time)
    window:draw()
end


-- we have the user provide the x, y, width, height separately because 
-- they shouldn't operate under the delusion that changing the window.width 
-- would actually change the window width. The user should use 
-- `request_geometry_change` for that.
local function create(app, x, y, width, height, args)

    -- TODO: set this properly with x11 properties
    -- local title = args.title 

    local xcb_window_defaults = {
        -- by default xcb windows should have titlebars
        wants_titlebar = true,

        draw = draw,

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
    local window = tpc_window.common_new(
        app,
        x, y, width, height,
        tt_table.crush(xcb_window_defaults, args)
    )

    -- then, create a window
    window.window_id = tpx_swin.create(
        app.xcb_ctx,
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

-- TODO: there should be a way for the user to know if his request was granted/denied
local function request_raise(window)
    tpx_swin.map_request(window.scope.app.xcb_ctx, window.window_id)
end

local function request_geometry_change(window, x, y, width, height)
    local window_geom = window:get_geometry()
    if window_geom.x == x 
        and window_geom.y == y 
        and window_geom.width == width 
        and window_geom.height == height 
    then 
        return 
    end

    tpx_swin.set_geometry_request(window.window_id, x, y, width, height)
end

local function hide(window)
    tpx_swin.unmap(window.scope.app.xcb_ctx, window.window_id)
end

local function destroy(window)
    _window_drawing_context_destroy(window)
    tpx_swin.destroy(window.window_id)
end

return {
    create = create,
    destroy = destroy,
    hide = hide,

    request_raise = request_raise,
    request_geometry_change = request_geometry_change,

    set_tree = tpc_window.set_tree,
    draw = draw,

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

