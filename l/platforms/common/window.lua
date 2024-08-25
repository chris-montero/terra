
local lev = require("ev")
local tstation = require("tstation")

local t_object = require("terra.object")
local t_sigtools = require("terra.sigtools")
local t_element = require("terra.element")

local tt_table = require("terra.tools.table")

local visibility = {
    HIDDEN = 0,
    RAISED = 1,
    RAISED_AND_SHOWING = 2,
}

local function set_tree(window, new_tree)

    if window.tree == tree then return end -- nothing changed

    local old_tree = window.tree
    if old_tree == nil then
        if tree == nil then -- nothing to do
            return
        else -- old tree is nil, set new tree
            window.tree = tree
            tree:handle_attach_to_window(window, window.scope.app)
        end
    else
        -- remove the old tree
        old_tree:handle_detach_from_window(window, window.scope.app)
        if tree == nil then
            window.tree = nil
        else -- set the new tree
            tree:handle_attach_to_window(window, window.scope.app)
            window.tree = tree
        end
    end
end

local function set_max_fps(window, fps)
    if fps < 0 then fps = 0 end
    if fps == nil then fps = 300 end -- TODO: add support for unlimited fps

    if fps == window.max_fps then return end
    window.max_fps = fps

    if fps == 0 then
        window._draw_every = 0
        window.frame_timer:stop(window.scope.app.event_loop)
    else
        window._draw_every = 1/fps

        -- draw it instantly after setting the fps. the draw function 
        -- should take care to reset the timer properly.
        window:draw()
    end
end

local function reset_frame_timer(window)
    window.frame_timer:again(window.scope.app.event_loop, window._draw_every)
end

local function setup_signals(window, parent_app)
    -- TODO: make these work so that the user can set them to nil
    t_sigtools.setup_subscribe_on_object_signals(window, "self", window)
    t_sigtools.setup_subscribe_on_object_signals(parent_app, "app", window)
end

local function teardown_signals(window, parent_app)
    t_sigtools.teardown_subscribe_on_object_signals(window, "self", window)
    t_sigtools.teardown_subscribe_on_object_signals(parent_app, "app", window)
end

local function check_valid(app, x, y, width, height)
    assert(app ~= nil, "You must provide a valid <terra.app>.")
    assert(x ~= nil, "You must provide a x coord.")
    assert(y ~= nil, "You must provide a y coord.")
    assert(width ~= nil, "You must provide a width property.")
    assert(height ~= nil, "You must provide a height property.")
end

local function window_common_new(app, x, y, width, height, args)

    -- TODO: document supported fields
    local window_defaults = {
        -- model = model -- NOTE: the user provides a model if he wants

        -- tree = nil, -- to be set by the user

        -- TODO: check which screen this window is on, and try to get the 
        -- refresh rate and use that by default
        max_fps = 144,
        _draw_every = nil,

        -- signal handling
        subscribe_on_self = {},
        subscribe_on_app = {},

        scope = {
            app = app,
        },

        set_max_fps = set_max_fps,
        reset_frame_timer = reset_frame_timer,

        -- by default, all windows are "hidden"
        visibility = visibility.HIDDEN,
    }
    local window = tt_table.crush(t_element.new(), window_defaults, args)
    check_valid(window.scope.app, x, y, width, height)

    -- set the timer callback
    window._timer_cb = function(loop, timer, revents)
        window:draw()
    end

    -- create the frame timer
    if window.max_fps == 0 then
        window._draw_every = 0
        -- "after" and "repeat" do not matter here because the timer is not 
        -- started anyway. when the timer will be started, these values will 
        -- be set properly then.
        window.frame_timer = lev.Timer.new(window._timer_cb, 0.1, 0.1) 
    else
        window._draw_every = 1/window.max_fps
        window.frame_timer = lev.Timer.new(window._timer_cb, window._draw_every, window._draw_every)
        -- window.frame_timer:start(app.event_loop, true) -- TODO: try with daemon=true
        window.frame_timer:start(app.event_loop) -- TODO: try with daemon=true
    end

    -- the scope should contain a reference to self
    window.scope.self = window

    -- always set the initial window.geometry
    window:set_geometry(x, y, width, height)

    -- setup the signals
    setup_signals(window, app)

    -- set the tree if there is one.
    if window.tree ~= nil then
        window.tree:handle_attach_to_window(window, window.scope.app)
    end

    -- TODO: maybe add functionality to allow users to move a window from one 
    -- <terra.app> to another? If so, we need to handle signals properly.

    return window
end

return {
    common_new = window_common_new,
    check_valid = check_valid,
    visibility = visibility,

    setup_signals = setup_signals,
    teardown_signals = teardown_signals,

    set_max_fps = set_max_fps,
    reset_frame_timer = reset_frame_timer,
}
