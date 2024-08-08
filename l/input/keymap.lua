
-- Glossary:
--     * key_id:
--         - a table used to identify a specific modifier + key combination
--         - also called a "kid"
--         For example: {
--             "key" : <string>,
--             "modifiers" : <number> (a 16 bit bitmap where each bit represents one modifier. Except for the special "MOD_ANY" modifier)
--             "is_press" : <boolean>
--         }
--     * keybind:
--         - just like a `key_id` but with a "callback" field to denote the 
--             callback to be called when the key combination matches
--     * keybindings:
--         - a contiguous array of `keybind` values
--     * keymap:
--         - a table of the form { <string> : { <string>|<int> : { <boolean> : <function(window_id)> } } }.
--             In the first table the <string> index is a modifier mask turned 
--             into string form. In the second, nested table, the key is a 
--             <string> to denote the "key" name, or, it can be an integer 
--             index which is treated as a literal keycode. The third nested 
--             table is the table that uses a boolean to determine whether 
--             the callback is for a key press event (true), or for a key 
--             release event (false). The <function> is the callback that 
--             exists at the given modifier + key + is_press combination.

-- create a "keymap" from "keybindings".
local function from_keybindings(keybindings)
    local keymap = {}
    for _, keybind in ipairs(keybindings) do
        local str_mods = tostring(keybind.modifiers)
        local keys = keymap[str_mods]
        if keys == nil then
            keys = {}
            keymap[str_mods] = keys
        end
        keys[keybind.key] = {
            [true] = keybind.on_press,
            [false] = keybind.on_release,
        }
    end
    return keymap
end

-- indexes the given "keymap" with the given "key_id", to give back a 
-- callback, if there is one
local function index(keymap, kid)
    local keys = keymap[tostring(kid.modifiers)]
    if keys == nil then return end
    local key = kid.key

    -- TODO: I don't think this applies anymore
    -- FIXME: the "`" or "grave" key doesn't work properly. When using
    -- `subscribe_key` to subscribe to events of this key, using "grave" 
    -- as the `.key` name works to subscribe, but when we get an event 
    -- from the C side, instead of giving us "grave" back as the `.key`, 
    -- it gives us '`'. This fixes the issue, but I'd like to fix it 
    -- properly from the C side.
    if key == '`' then key = "grave" end
    local press_or_release = keys[key]
    local cb = press_or_release[kid.is_press]
    return cb
end

return {
    from_keybindings = from_keybindings,
    index = index,
}
