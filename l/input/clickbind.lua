
-- `on_press` or `on_release` can be nil, but not both
local function new(button, modifiers, on_press, on_release)

    if on_press == nil and on_release == nil then 
        error("cannot create a clickbind where both `on_press` and `on_release` are nil.")
    end

    return {
        button = button,
        modifiers = modifiers,
        on_press = on_press,
        on_release = on_release,
    }
end

return {
    new = new
}
