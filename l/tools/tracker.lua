
-- A tool for tracking elements. Most notably used in tracking elements 
-- under the mouse for emitting MouseEnterEvent and MouseLeaveEvent events.

local function new()
    return {
        list = {},
        mapping = {},
    }
end

local function track(tracker, elem)
    table.insert(tracker.list, elem)
    tracker.mapping[elem.oak_private.id] = elem
end

local function reset(tracker)
    for k, elem in ipairs(tracker.list) do
        tracker.list[k] = nil
        tracker.mapping[elem.oak_private.id] = nil
    end
end

local function iter(tracker)
    local i = 0
    return function()
        i = i + 1
        return tracker.list[i]
    end
end

local function contains(tracker, elem)
    return tracker.mapping[elem.oak_private.id] ~= nil
end

return {
    new = new,

    track = track,
    reset = reset,
    iter = iter,
    contains = contains,
}

