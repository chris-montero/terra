
-- on_press or on_release can be nil, but not both
local function new(keyname, modifiers, on_press, on_release)

    if on_press == nil and on_release == nil then
        error("cannot create a keybind without either `on_press` or `on_release`")
    end

    return {
        key = keyname,
        modifiers = modifiers,
        on_press = on_press,
        on_release = on_release,
    }
end

return {
    new = new
}

