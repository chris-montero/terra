-- TODO: move this to terra.internal

local function new()
    -- a mapping of <window_id>s to <terra.window>s
    return {}
end

local function add_window(orchard, window)
    orchard[window.window_id] = window
end

local function get_window_by_id(orchard, window_id)
    return orchard[window_id]
end

local function remove_window_by_id(orchard, window_id)
    orchard[window_id] = nil
end

return {
    new = new,
    add_window = add_window,
    get_window_by_id = get_window_by_id,
    remove_window_by_id = remove_window_by_id,
}

