
local tstation = require("tstation")

local t_i_unveil = require("terra.internal.unveil")

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

    -- if tree == nil then
    --     if window.tree == nil then
    --         return
    --     else
    --         window.tree = nil
    --         tree:handle_detach_from_window(window, window.scope.app)
    --     end
    -- else
    --     if window.tree ~= nil then
    --         tree:handle_detach_from_window(window, window.scope.app)
    --     end
    --
    --     window.tree = tree 
    --     -- finally, let the tree know it was attached to a window
    --     tree:handle_attach_to_window(window, window.scope.app)
    -- end
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

    -- local title = args.title -- TODO: set this properly with x11 properties

    local window_defaults = {

        -- model = model -- NOTE: the user provides a model if he wants

        -- tree = nil, -- to be set by the user

        -- for now, by default, all windows have a max_fps of 144. TODO: make 
        -- it so that each window can set its own fps.
        max_fps = 144,

        -- signal handling
        subscribe_on_self = {},
        subscribe_on_app = {},

        scope = {
            app = app,
        },

        -- by default, all windows are "hidden"
        visibility = visibility.HIDDEN,
    }

    -- TODO: document supported fields
    local window = tt_table.crush(t_element.new(), window_defaults, args)

    check_valid(window.scope.app, x, y, width, height)

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

}
