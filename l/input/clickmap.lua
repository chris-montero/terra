
local i_click = require("input.click")
local i_key = require("input.key")

-- Glossary:
--     * click_id:
--         - a table used to identify a specific modifier + click combination
--         - also called a "cid"
--         For example: {
--             "button" : <number>, (the mouse button number. e.g. 1 for left click, 2 for right click, etc.)
--             "modifiers" : <number> (a 16 bit bitmap where each bit represents one modifier. Except for the special "MOD_ANY" modifier)
--             "is_press : <boolean>
--         }
--     * clickbind:
--         - just like a `click_id` but with a "callback" field to denote the 
--             callback to be called when the click combination matches
--     * clickbindings:
--         _ a contiguous array of `clickbind` values
--     * clickmap:
--         - a table of the form { <string> : { <int> : <function(click_event)> } }.
--             In the first table the <string> index is a modifier mask turned 
--             into string form. In the second, nested table, the key is an
--             <int> to denote the "button". The <function> is the callback 
--             that exists at the given modifier + button combination.
--         - normally used to index into with a `click_id`, in order to 
--             execute a clickbinding


-- create a "clickmap" from "clickbindings"
local function from_clickbindings(clickbindings)
    local clickmap = {}
    for _, clickbind in ipairs(clickbindings) do

        local str_mods = tostring(clickbind.modifiers)
        local buttons = clickmap[str_mods]
        if buttons == nil then
            buttons = {}
            clickmap[str_mods] = buttons
        end

        buttons[clickbind.button] = {
            [true] = clickbind.on_press,
            [false] = clickbind.on_release,
        }
    end
    return clickmap
end

-- indexes the given "clickmap" with the given "click_id", to give back a 
-- callback, if there is one
local function index(clickmap, cid)
    local buttons = clickmap[tostring(cid.modifiers)]
    if buttons == nil then
        -- buttons are nil, so try with "any modifiers"
        buttons = clickmap[tostring(i_key.MOD_ANY)]
    end
    if buttons == nil then return end
    local press_or_release = buttons[cid.button]
    if press_or_release == nil then
        press_or_release = buttons[i_click.ANY]
    end
    if press_or_release == nil then return end
    local cb = press_or_release[cid.is_press]
    return cb
end

return {
    from_clickbindings = from_clickbindings,
    index = index,
}

