
local tt_table = require("terra.tools.table")

local t_element = require("terra.element")
local t_sigtools = require("terra.sigtools")
local toe_internal = require("terra.oak.elements.internal")

local function set_offset_x(element, value)
    toe_internal.default_oak_prop_set(element, "offset_x", value)
end

local function set_offset_y(element, value)
    toe_internal.default_oak_prop_set(element, "offset_y", value)
end

local function set_oak_draw(element, value)
    toe_internal.default_oak_prop_set(element, "oak_draw", value)
end

local function set_opacity(element, value)
    toe_internal.default_oak_prop_set(element, "opacity", value)
end

local function new()

    local element_defaults = {
        oak_private = {
            -- use an empty function as an ID. TODO: check if this is efficient
            id = function() end,
            needs_redraw = false,
        },
        scope = {
            -- will be set when the element gets attached to an attached parent:
            -- root : <root_ref>
            -- window : <window_ref>
            -- parent : <parent_ref>
            -- self : <self_ref>
            -- app : <app_ref>
        },

        -- TODO: make it so that these should only ever be user-defined.
        subscribe_on_self = {},
        subscribe_on_parent = {},
        subscribe_on_root = {},
        subscribe_on_window = {},
        subscribe_on_app = {},

        -- transform-related property setters
        set_offset_x = set_offset_x,
        set_offset_y = set_offset_y,
        -- TODO: implement scale_x, scale_y, rotate, origin

        -- drawing related property setters
        set_oak_draw = set_oak_draw,
        set_opacity = set_opacity,
    }

    return tt_table.crush(t_element.new(), element_defaults)
end

local function element_setup_signals(element, parent_element, parent_root, parent_window, parent_app)
    t_sigtools.setup_subscribe_on_object_signals(element, "self", element)
    t_sigtools.setup_subscribe_on_object_signals(parent_element, "parent", element)
    t_sigtools.setup_subscribe_on_object_signals(parent_root, "root", element)
    t_sigtools.setup_subscribe_on_object_signals(parent_window, "window", element)
    t_sigtools.setup_subscribe_on_object_signals(parent_app, "app", element)
end

local function element_teardown_signals(element, parent_element, parent_root, parent_window, parent_app)
    t_sigtools.teardown_subscribe_on_object_signals(element, "self", element)
    t_sigtools.teardown_subscribe_on_object_signals(parent_element, "parent", element)
    t_sigtools.teardown_subscribe_on_object_signals(parent_root, "root", element)
    t_sigtools.teardown_subscribe_on_object_signals(parent_window, "window", element)
    t_sigtools.teardown_subscribe_on_object_signals(parent_app, "app", element)
end

local function default_oak_handle_attach_to_parent_element(element, parent, root, window, app)

    element.scope.self = element
    element.scope.parent = parent
    element.scope.root = root
    element.scope.window = window
    element.scope.app = app

    element_setup_signals(element, parent, root, window, app)
end

local function default_oak_handle_detach_from_parent_element(element, parent, root, window, app)

    element.scope.self = nil
    element.scope.parent = nil
    element.scope.root = nil
    element.scope.window = nil
    element.scope.app = nil

    element_teardown_signals(element, parent, root, window, app)
end


return {
    -- constructor
    new = new,

    set_offset_x = set_offset_x,
    set_offset_y = set_offset_y,
    set_oak_draw = set_oak_draw,
    set_opacity = set_opacity,

    default_oak_handle_attach_to_parent_element = default_oak_handle_attach_to_parent_element,
    default_oak_handle_detach_from_parent_element = default_oak_handle_detach_from_parent_element,
}

