
local luv = require("luv")

local t_platform = require("terra.platform")
local t_object = require("terra.object")
local t_orchard = require("terra.orchard")

local tt_table = require("terra.tools.table")
local tpx_ctx = require("terra.platforms.xcb.ctx")

local events = {
    X_ClickEvent = "X_ClickEvent",
    X_ConfigureNotify = "X_ConfigureNotify",
    X_CreateNotify = "X_CreateNotify",
    X_DestroyNotify = "X_DestroyNotify",
    X_EnterNotify = "X_EnterNotify",
    X_ExposeEvent = "X_ExposeEvent",
    X_FocusIn = "X_FocusIn",
    X_FocusOut = "X_FocusOut",
    X_KeyEvent = "X_KeyEvent",
    X_LeaveNotify = "X_LeaveNotify",
    X_MotionEvent = "X_MotionEvent",
    X_MapNotify = "X_MapNotify",
    X_MapRequest = "X_MapRequest",
    X_PropertyNotify = "X_PropertyNotify",
    X_ReparentNotify = "X_ReparentNotify",
    X_VisibilityNotify = "X_VisibilityNotify",
    X_UnmapNotify = "X_UnmapNotify",
}

local function handle_configure_notify_event(app, event_type, window_id, x, y, width, height)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_configure_notify_event(x, y, width, height)
end

local function handle_mouse_click_event(app, event_type, window_id, is_press, button, modifiers, x, y)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_mouse_click_event(is_press, button, modifiers, x, y)
end

local function handle_create_event(app, event_type, parent_id, window_id, x, y, width, height)
    local window = t_orchard.get_window_by_id(app.orchard, parent_id)
    window:handle_create_event()
end

local function handle_destroy_event(window, event_type, parent_id, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_destroy_event()
end

local function handle_mouse_enter_event(app, event_type, window_id, button, modifiers, x, y)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_mouse_enter_event(button, modifiers, x, y)
end

local function handle_expose_event(app, event_type, window_id, x, y, width, height, count)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_expose_event(x, y, width, height, count)
end

local function handle_focus_in_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_focus_in_event()
end

local function handle_focus_out_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_focus_out_event()
end

local function handle_key_event(app, event_type, window_id, is_press, key, modifiers)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_key_event(is_press, key, modifiers)
end

local function handle_mouse_leave_event(app, event_type, window_id, button, modifiers, x, y)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_mouse_leave_event(button, modifiers, x, y)
end

local function handle_mouse_motion_event(app, event_type, window_id, modifiers, x, y)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_mouse_motion_event(modifiers, x, y)
end

local function handle_map_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_map_event()
end

local function handle_map_request(app, event_type, parent_id, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, parent_id)
    window:handle_map_request(window_id)
end

local function handle_property_event(app, event_type, window_id, atom, time, state)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_property_event(atom, time, state)
end

local function handle_reparent_event(app, event_type, event_window_id, parent_id, window_id, x, y)
    -- this happens when a window is reparented to us, or when our window
    -- is reparented onto another. I'm not sure what to do about this yet,
    -- so let's just mark everything for relayout and redraw.
    -- ou_internal.element_mark_relayout(window)
    -- ou_internal.element_mark_redraw(window)
end

local function handle_visibility_event(app, event_type, window_id, visibility)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_visibility_event(visibility)
end

local function handle_unmap_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    window:handle_unmap_event()
end

local default_event_handler_map = {
    [events.X_ClickEvent] = handle_mouse_click_event,
    [events.X_ConfigureNotify] = handle_configure_notify_event,
    [events.X_CreateNotify] = handle_create_event,
    [events.X_DestroyNotify] = handle_destroy_event,
    [events.X_EnterNotify] = handle_mouse_enter_event,
    [events.X_ExposeEvent] = handle_expose_event,
    [events.X_FocusIn] = handle_focus_in_event,
    [events.X_FocusOut] = handle_focus_out_event,
    [events.X_KeyEvent] = handle_key_event,
    [events.X_LeaveNotify] = handle_mouse_leave_event,
    [events.X_MotionEvent] = handle_mouse_motion_event,
    [events.X_MapNotify] = handle_map_event,
    [events.X_MapRequest] = handle_map_request,
    [events.X_PropertyNotify] = handle_property_event,
    [events.X_ReparentNotify] = handle_reparent_event,
    [events.X_VisibilityNotify] = handle_visibility_event,
    [events.X_UnmapNotify] = handle_unmap_event,
}

local function make_default_event_handler(user_event_handler)
    return function(app, event_type, ...)
        local cb = default_event_handler_map[event_type]
        if cb == nil then
            return user_event_handler(app, event_type, ...)
        else
            return cb(app, event_type, ...)
        end
    end
end

local function desktop(init_func, event_handler)
    local app = tt_table.crush(t_object.new(), {
        -- we use a <terra.orchard> to keep track of all of the windows
        orchard = t_orchard.new(),
        -- user can set a ".model" field if he wants
    })

    -- the xcb_ctx is a bunch of stuff from the C side that we need in
    -- order to have the application work
    app.xcb_ctx = tpx_ctx.create(function(...)
        return event_handler(app, ...)
    end)

    -- create the X11 file descriptor watcher
    app.xcb_watcher = luv.new_poll(tpx_ctx.get_file_descriptor(app.xcb_ctx))
    luv.poll_start(app.xcb_watcher, "r", function(err, events)
        tpx_ctx.handle_events()
    end)

    -- let the user initialize his data
    init_func(app)

    -- start the event loop
    luv.run()

    -- this only runs after the event loop is stopped.
    -- normally, when the application is done.
    tpx_ctx.destroy()
end

-- -- function that allows the user to listen to events on a user-supplied 
-- -- file descriptor.
-- -- @fun: (loop, watcher, revents) -> nil
-- local function watch_io(app, fd, fun)
--     -- The way to stop an io watcher created with this function is by 
--     -- calling a ":stop(loop)" method on the return value. I dislike 
--     -- APIs like this. TODO: Maybe fork lua-ev and write my own api.
--     local watcher = lev.IO.new(fun, fd, ev.READ) -- TODO: use bitlib
--     watcher:start(app.event_loop)
--     return watcher
-- end

-- -- TODO: implement this. This function lets the user simulate an event 
-- -- directly onto the event loop and have it handled as a regular event.
-- local function event(app, name, ...)
-- end

-- local function desktop(init_func, event_handler)
--     t_i_application.desktop(
--         function(terra_data) -- initialization function
--
--             -- Inheritance usually sucks but since we always need to have a <tstation> 
--             -- "station" field on each <terra.application>, <terra.window>, and 
--             -- element, it makes sense to make our lives easier this way.
--             local app = tt_table.crush(t_object.new(), {
--                 -- we use a <terra.orchard> to keep track of all of the windows
--                 orchard = t_orchard.new(),
--                 -- the terra data is a bunch of stuff from the C side that we need in
--                 -- order to have the application work
--                 terra_data = terra_data,
--                 -- the ".model" should be set by the user if it makes sense to have one
--             })
--
--             init_func(app)
--
--             return app
--         end, 
--         event_handler
--     )
-- end


return {
    -- supported events names
    events = events,

    default_event_handler_map = default_event_handler_map,
    -- app default xcb handlers
    handle_mouse_click_event = handle_mouse_click_event,
    handle_configure_notify_event = handle_configure_notify_event,
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

    make_default_event_handler = make_default_event_handler,

    -- create and run the app
    desktop = desktop,

    -- -- app tools
    -- watch_io = watch_io,

    -- TODO: see if I can get rid of these things
    -- sync = t_i_application.sync,
    -- flush = t_i_application.flush,
}
