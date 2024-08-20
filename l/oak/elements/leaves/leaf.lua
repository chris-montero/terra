
local tt_table = require("terra.tools.table")

local toe_element = require("terra.oak.elements.element")
local toe_internal = require("terra.oak.elements.internal")

local function new()

    local leaf_defaults = {
        oak_handle_attach_to_parent_element = toe_element.default_oak_handle_attach_to_parent_element,
        oak_handle_detach_from_parent_element = toe_element.default_oak_handle_detach_from_parent_element,

        -- convenience element self-removal method
        remove = toe_internal.element_remove,
    }

    return tt_table.crush(toe_element.new(), leaf_defaults)
end

return {
    new = new,

    remove = toe_internal.element_remove,
}

