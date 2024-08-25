
-- TODO: make it so that the user has the option to either handle platform specific events directly or abstract them away automatically
-- LEFTOFF: make signals work on windows properly

local te_xcb = require("terra.events")

local events = te_xcb.events

-- -- TODO: this should automatically clean up after itself
-- local function destroy(window)
--
--     twindow.destroy(window)
--     tsoil.destroy(window.soil)
--
--     if window.branch == nil then return end
--
--     -- TODO: maybe the user should manually detach the branch?
--     ou_internal.element_recursively_detach(window.branch)
--
--     _root_unsubscribe_functions(root, root.model)
--
-- end

local function _handle_configure_notify_event(window, event_type, window_id, x, y, width, height)

    local size_changed = false

    if window.width ~= event.width or window.height ~= event.height then
        size_changed = true
    end

    window.x = event.x
    window.y = event.y
    window.width = event.width
    window.height = event.height

    local tree = window.tree
    if tree == nil then return end

    if size_changed then
        tstation.emit(tree.station, tree, t_i_e_tree.ParentWindowSizeChanged, width, height)
    end
end

local function _handle_click_event(window, event_type, window_id, is_press, button, modifiers, x, y)

    local tree = window.tree
    if tree == nil then return end
    if x > tree.width or y > tree.height then return end

    tstation.emit(tree.station, tree, t_i_e_tree.MouseClickEvent, is_press, button, modifiers, x, y)
end

local function _handle_create_event(app, ...)
    -- this can only happen if someone creates a window with us as the parent.
    -- this is currently not supported, so we do nothing.
end

local function _handle_destroy_event(window, event_type, parent_id, window_id)

    _window_drawing_context_destroy(window)

    local tree = window.tree
    if tree == nil then return end

    -- TODO: also let each child element know about this

    tstation.emit(window.station, window, event_type, window_id)
end

local function _handle_enter_event(app, event_type, window_id, ...)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_expose_event(app, event_type, window_id, ...)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_focus_in_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    -- window.focused = true -- TODO: move this out of here
    tstation.emit(window.station, window, event_type, window_id)
end

local function _handle_focus_out_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    -- window.focused = false -- TODO: move this out of here
    tstation.emit(window.station, window, event_type, window_id)
end

local function _handle_key_event(app, event_type, window_id, ...)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    -- TODO: set keybindings on windows directly

    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_leave_event(app, event_type, window_id, ...)

    local window = t_orchard.get_window_by_id(app.orchard, window_id)

    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_motion_event(app, event_type, window_id, ...)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    tstation.emit(window.station, window, event_type, window_id, ...)

    -- TODO: move this code where it belongs
    -- local hit_children = ou_internal.get_approved_mouse_hit_children(
    --     window,
    --     event_type,
    --     event.x,
    --     event.y
    -- )
    --
    -- for _, child in ipairs(hit_children) do
    --     local geom = child.oak_geometry
    --     tstation.emit(child.station, {
    --         type = event_type,
    --         -- translate the coordinates so the child gets relative coordinates
    --         x = event.x - geom.x,
    --         y = event.y - geom.y,
    --     })
    -- end
end

local function _handle_map_event(app, event_type, window_id, ...)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    -- TODO: move this out of here
    -- window.visibility = tw_internal.visibility.RAISED

    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_map_request(app, event_type, parent_id, window_id)
    -- this could only happen if we had child windows and one of them 
    -- would request to be mapped. This is currently not supported.
end

local function _handle_property_event(app, event_type, window_id, ...)
    -- TODO: implement this properly
    local window = t_orchard.get_window_by_id(app.orchard, window_id)
    tstation.emit(window.station, window, event_type, window_id, ...)
end

local function _handle_reparent_event(app, event)
    -- this happens when a window is reparented to us, or when our window
    -- is reparented onto another. I'm not sure what to do about this yet,
    -- so let's just mark everything for relayout and redraw.
    -- ou_internal.element_mark_relayout(window)
    -- ou_internal.element_mark_redraw(window)
end

local function _handle_visibility_event(app, event_type, window_id, visibility)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)

    -- TODO: move this out of here
    -- window.visibility = tw_internal.visibility.RAISED_AND_SHOWING

    tstation.emit(window.station, window, event_type, window_id, visibility)
end

local function _handle_unmap_event(app, event_type, window_id)
    local window = t_orchard.get_window_by_id(app.orchard, window_id)

    -- TODO: move this out of here
    -- window.visibility = tw_internal.visibility.HIDDEN

    tstation.emit(window.station, window, event_type, window_id)
end




local default_event_handler_map = {

    -- platform specific events
    [events.X_ClickEvent] = _handle_click_event,
    [events.X_ConfigureNotify] = _handle_configure_notify_event,
    [events.X_CreateNotify] = _handle_create_event,
    [events.X_DestroyNotify] = _handle_destroy_event,
    [events.X_EnterNotify] = _handle_enter_event,
    [events.X_ExposeEvent] = _handle_expose_event,
    [events.X_FocusIn] = _handle_focus_in_event,
    [events.X_FocusOut] = _handle_focus_out_event,
    [events.X_KeyEvent] = _handle_key_event,
    [events.X_LeaveNotify] = _handle_leave_event,
    [events.X_MotionEvent] = _handle_motion_event,
    [events.X_MapNotify] = _handle_map_event,
    [events.X_MapRequest] = _handle_map_request,
    [events.X_PropertyNotify] = _handle_property_event,
    [events.X_ReparentNotify] = _handle_reparent_event,
    [events.X_VisibilityNotify] = _handle_visibility_event,
    [events.X_UnmapNotify] = _handle_unmap_event,
}


return {
    events = events,
    default_event_handler_map = default_event_handler_map,
}
