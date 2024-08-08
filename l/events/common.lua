
local tstation = require("tstation")
local t_time = require("terra.time")

local events = {
    FrameEvent = "FrameEvent",
}

local function _handle_frame_event(app, event_type, time)
    -- TODO: maybe add an iterator for <terra.orchard>
    for _, window in pairs(app.orchard) do
        window:handle_frame_event(time)
    end
end

local default_event_handler_map = {
    [events.FrameEvent] = _handle_frame_event,
}

return {
    events = events,
    default_event_handler_map = default_event_handler_map,
}

