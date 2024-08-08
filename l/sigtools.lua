
local tstation = require("tstation")

local function setup_subscribe_on_object_signals(obj_a, name, obj_b)

    -- NOTE: we keep track of this function because we're going to need it 
    -- in order to unsubscribe upon destruction.
    obj_b["subscribe_on_" .. name .. "_event_handler"] = function(event_type, ...)
        -- print(event_type)
        local handler = obj_b["subscribe_on_" .. name][event_type]
        -- print("handler:", handler)
        if handler == nil then return end
        return handler(obj_b, ...)
    end
    tstation.subscribe_function(obj_a.station, obj_b["subscribe_on_" .. name .. "_event_handler"])
end

local function teardown_subscribe_on_object_signals(obj_a, name, obj_b)
    tstation.unsubscribe_function(obj_a.station, obj_b["subscribe_on_" .. name .. "_event_handler"])
end

return {
    setup_subscribe_on_object_signals = setup_subscribe_on_object_signals,
    teardown_subscribe_on_object_signals = teardown_subscribe_on_object_signals,
}
