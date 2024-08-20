
local tt_table = require("terra.tools.table")

local toe_internal = require("terra.oak.elements.internal")
local toe_element = require("terra.oak.elements.element")

local function oak_handle_attach_to_parent_element(branch, parent, root, window, app)
    toe_element.default_oak_handle_attach_to_parent_element(branch, parent, root, window, app)
    for key, child in branch:oak_children_iter() do
        branch.oak_private.child_id_to_index[child.oak_private.id] = key
        child:oak_handle_attach_to_parent_element(branch, root, window, app)
    end
end

local function oak_handle_detach_from_parent_element(branch, parent, root, window, app)
    toe_element.default_oak_handle_detach_from_parent_element(branch, parent, root, window, app)
    for _, child in branch:oak_children_iter() do
        child:oak_handle_detach_from_parent_element(branch, root, window, app)
    end
end

local function default_oak_children_iter(branch)

    local co = coroutine.create(function()
        if branch.bg ~= nil then
            coroutine.yield("bg", branch.bg)
        end
        if branch.shadow ~= nil then
            coroutine.yield("shadow", branch.shadow)
        end
        for i=1, #branch do
            coroutine.yield(i, branch[i])
        end
    end)

    return function()
        local is_not_finished, k, v = coroutine.resume(co)
        if is_not_finished then
            return k, v
        else
            return nil, nil
        end
    end
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
        oak_children_iter = default_oak_children_iter,

        -- branch specific attach/detach functions
        oak_handle_attach_to_parent_element = oak_handle_attach_to_parent_element,
        oak_handle_detach_from_parent_element = oak_handle_detach_from_parent_element,

        -- default branch-specific property setters
        set_bg = toe_internal.set_bg,
        set_shadow = toe_internal.set_shadow,
        set_child_n = toe_internal.set_child_n,
        insert_child_n = toe_internal.insert_child_n,
        remove_child_n = toe_internal.remove_child_n,
        remove = toe_internal.element_remove,

        set_valign = set_valign,
        set_halign = set_halign,
        set_padding = set_padding,
    }

    local branch = tt_table.crush(toe_element.new(), branch_defaults)
    -- we use this to keep track of the index of each child set. This makes 
    -- it easier to have a "remove_element" function where you only have to 
    -- supply the element itself.
    branch.oak_private.child_id_to_index = {}
    return branch
end

return {
    new = new,

    oak_handle_attach_to_parent_element = oak_handle_attach_to_parent_element,
    oak_handle_detach_from_parent_element = oak_handle_detach_from_parent_element,

    default_oak_children_iter = default_oak_children_iter,

    set_bg = toe_internal.set_bg,
    set_shadow = toe_internal.set_shadow,
    set_child_n = toe_internal.set_child_n,
    insert_child_n = toe_internal.insert_child_n,
    remove_child_n = toe_internal.remove_child_n,
    remove = toe_internal.element_remove,

    set_valign = set_valign,
    set_halign = set_halign,
    set_padding = set_padding,
}

