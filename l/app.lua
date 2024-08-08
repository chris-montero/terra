
local t_object = require("terra.object")
local t_orchard = require("terra.orchard")
local t_i_application = require("terra.internal.application")
local tt_table = require("terra.tools.table")

local te_specific = require("terra.events." .. t_i_application.get_platform())
local te_common = require("terra.events.common")

local default_event_handler_map = tt_table.crush(te_specific.default_event_handler_map, te_common.default_event_handler_map)

local function make_default_event_handler(user_event_handler)
    return function(terra_data, app, event_type, ...) 
        local cb = default_event_handler_map[event_type]
        if cb == nil then 
            return user_event_handler(app, event_type, ...)
        else
            return cb(app, event_type, ...)
        end
    end
end

local function desktop(init_func, event_handler)
    t_i_application.desktop(
        function(terra_data) -- initialization function

            -- Inheritance usually sucks but since we always need to have a <tstation> 
            -- "station" field on each <terra.application>, <terra.window>, and 
            -- element, it makes sense to make our lives easier this way.
            local app = tt_table.crush(t_object.new(), {
                -- we use a <terra.orchard> to keep track of all of the windows
                orchard = t_orchard.new(),
                -- the terra data is a bunch of stuff from the C side that we need in
                -- order to have the application work
                terra_data = terra_data,
                -- the ".model" should be set by the user if it makes sense to have one
            })

            init_func(app)

            return app
        end, 
        event_handler
    )
end


return {
    default_event_handler_map = default_event_handler_map,
    make_default_event_handler = make_default_event_handler,
    desktop = desktop,

    -- TODO: see if I can get rid of these things
    sync = t_i_application.sync,
    flush = t_i_application.flush,
    get_platform = t_i_application.get_platform,
}
