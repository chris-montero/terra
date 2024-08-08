
local tt_table = require("terra.tools.table")

local toe_element = require("terra.oak.elements.element")

local function new()

    local leaf_defaults = {
        oak_handle_attach_to_parent_element = toe_element.default_oak_handle_attach_to_parent_element,
        oak_handle_detach_from_parent_element = toe_element.default_oak_handle_detach_from_parent_element,
    }

    return tt_table.crush(toe_element.new(), leaf_defaults)
end

return {
    new = new,
}

