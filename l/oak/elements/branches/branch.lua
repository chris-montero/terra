
local tt_table = require("terra.tools.table")

local toe_internal = require("terra.oak.elements.internal")
local toe_element = require("terra.oak.elements.element")

local function oak_handle_attach_to_parent_element(branch, parent, root, window, app)
    toe_element.default_oak_handle_attach_to_parent_element(branch, parent, root, window, app)
    for _, child in ipairs(branch:oak_get_children()) do
        child:oak_handle_attach_to_parent_element(branch, root, window, app)
    end
end

local function oak_handle_detach_from_parent_element(branch, parent, root, window, app)
    toe_element.default_oak_handle_detach_from_parent_element(branch, parent, root, window, app)
    for _, child in ipairs(branch:oak_get_children()) do
        child:oak_handle_detach_from_parent_element(branch, root, window, app)
    end
end

-- TODO: use an iterator for this instead. That way I think we can also save 
-- up memory, it might be faster, and I think it will simplify some of the code.
-- This function should return all children in a contiguous array, in the order
-- we want the children to be drawn in
local function default_oak_get_children(branch)
    local all = {}
    if branch.shadow ~= nil then
        table.insert(all, branch.shadow)
    end
    if branch.bg ~= nil then
        table.insert(all, branch.bg)
    end
    -- TODO: make it so that an element can have "gaps" in children
    for _, child in ipairs(branch) do
        table.insert(all, child)
    end
    return all
end

-- TODO: make this also work with removal of children
local function help_set_child(branch, key, child)
    branch.children[key] = child
    toe_element.mark_redraw(branch)
    -- TODO: maybe make this also work on unattached branches
    child:oak_handle_attach_to_parent_element(
        branch, 
        branch.scope.root, 
        branch.scope.window, 
        branch.scope.app
    )
end

local function set_child(branch, n, child)
    help_set_child(branch, n, child)
end

local function set_bg(branch, child)
    help_set_child(branch, "bg", child)
end

local function set_shadow(branch, child)
    help_set_child(branch, "shadow", child)
end

local function set_halign(branch, halign)
    toe_element.default_oak_prop_set(branch, "halign", halign)
end

local function set_valign(branch, valign)
    toe_element.default_oak_prop_set(branch, "valign", valign)
end

local function set_padding(branch, padding)
    toe_element.default_oak_prop_set(branch, "padding", padding)
end

local function new()

    local branch_defaults = {

        -- part of the interface to be a <terra.oak.elements.branch>
        oak_get_children = default_oak_get_children,

        -- branch specific attach/detach functions
        oak_handle_attach_to_parent_element = oak_handle_attach_to_parent_element,
        oak_handle_detach_from_parent_element = oak_handle_detach_from_parent_element,

        -- default branch-specific property setters
        set_bg = set_bg,
        set_shadow = set_shadow,
        set_child = set_child,
        set_valign = set_valign,
        set_halign = set_halign,
        set_padding = set_padding,
    }

    return tt_table.crush(toe_element.new(), branch_defaults)
end

return {
    new = new,

    oak_handle_attach_to_parent_element = oak_handle_attach_to_parent_element,
    oak_handle_detach_from_parent_element = oak_handle_detach_from_parent_element,

    default_oak_get_children = default_oak_get_children,

    set_bg = set_bg,
    set_shadow = set_shadow,
    set_child = set_child,
    set_valign = set_valign,
    set_halign = set_halign,
    set_padding = set_padding,
}

