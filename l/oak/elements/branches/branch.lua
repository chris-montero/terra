
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

-- TODO: maybe make this also work on unattached branches
local function help_set_child(branch, child)
    toe_element.mark_redraw(branch)
    child:oak_handle_attach_to_parent_element(
        branch, 
        branch.scope.root, 
        branch.scope.window, 
        branch.scope.app
    )
end

-- TODO: maybe make this also work on unattached branches
local function help_remove_child(branch, child)
    toe_element.mark_redraw(branch)
    child:oak_handle_detach_from_parent_element(
        branch, 
        branch.scope.root, 
        branch.scope.window, 
        branch.scope.app
    )
end

local function custom_table_insert(branch, n, elem)

    -- make this work like the standard table.insert
    if elem == nil then
        elem = n
        n = #branch + 1
    end

    -- only let users append at the most. Gaps between children are not supported
    if n > #branch + 1 then
        n = #branch + 1 
    end

    -- shift all elements up
    for i=#branch, n, -1 do
        local existing_elem = branch[i]
        local new_index = i + 1
        branch.oak_private.child_id_to_index[existing_elem.oak_private.id] = new_index
        branch[new_index] = branch[i]
    end

    -- finally, insert the element
    branch.oak_private.child_id_to_index[elem.oak_private.id] = n
    branch[n] = elem
end

local function custom_table_remove(branch, n)

    local removed = nil
    local full_branch_l = #branch
    if n == nil then
        n = #branch
    end

    local target_elem = branch[n]
    if target_elem == nil then return removed end

    -- remove the element
    removed = branch[n]
    branch.oak_private.child_id_to_index[target_elem.oak_private.id] = nil
    branch[n] = nil

    -- shift everything down
    for i=n+1, full_branch_l do
        local existing_elem = branch[i]
        local new_index = i-1
        branch.oak_private.child_id_to_index[existing_elem.oak_private.id] = new_index
        branch[new_index] = branch[i]
    end

    return removed
end

local function insert_child_n(branch, n, elem)
    if elem == nil then
        elem = n
        n = #branch + 1
    end
    custom_table_insert(branch, n, elem)
    help_set_child(branch, elem)
end

local function remove_child_n(branch, n)
    local removed = custom_table_remove(branch, n)
    if removed == nil then return end
    help_remove_child(branch, removed)
end

local function set_child_n(branch, n, child)
    if branch[n] == child then return end -- nothing changed
    -- dont let users put gaps between children
    if n > #branch+1 then n = #branch + 1 end 
    local old_child = branch[n]
    if old_child == nil then
        if child == nil then -- nothing to do
            return
        else -- set new
            branch[n] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = n
            help_set_child(branch, child)
        end
    else
        if child == nil then -- remove old
            local removed = remove_child_n(branch, n) -- dont leave gaps
            if removed ~= nil then
                help_remove_child(branch, removed)
            end
        else -- replace old with new
            help_remove_child(branch, old_child)
            help_set_child(branch, child)
            branch[n] = child
            branch.oak_private.child_id_to_index[old_child.oak_private.id] = nil
            branch.oak_private.child_id_to_index[child.oak_private.id] = n
        end
    end
end

local function _set_prop_child_common(branch, str_key, child)

    if branch[str_key] == child then return end -- nothing changed

    if branch[str_key] == nil then
        if child == nil then -- nothing to do
            return
        else
            branch[str_key] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = str_key
            help_set_child(branch, child)
        end
    else
        -- remove the old one
        local old_child = branch[str_key]
        branch.oak_private.child_id_to_index[old_child.oak_private.id] = nil
        help_remove_child(branch, old_child)
        if child == nil then -- set new child as nil
            branch[str_key] = nil
        else -- set new child
            branch[str_key] = child
            branch.oak_private.child_id_to_index[child.oak_private.id] = str_key
            help_set_child(branch, child)
        end
    end
end

local function set_bg(branch, new_bg)
    _set_prop_child_common(branch, "bg", new_bg)
end

local function set_shadow(branch, new_shadow)
    _set_prop_child_common(branch, "shadow", new_shadow)
end

-- NOTE: this only works for already-attached elements
local function remove_element(element)
    local parent = element.scope.parent
    if parent == nil then return end -- not attached
    local element_key = parent.oak_private.child_id_to_index[element.oak_private.id]
    if element_key == nil then return end -- should never happen
    if element_key == "bg" then
        set_bg(parent, nil)
    elseif element_key == "shadow" then
        set_shadow(parent, nil)
    else
        remove_element_n(parent, element_index)
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
        set_bg = set_bg,
        set_shadow = set_shadow,
        set_child_n = set_child_n,
        insert_child_n = insert_child_n,
        remove_child_n = remove_child_n,
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

    set_bg = set_bg,
    set_shadow = set_shadow,
    set_child_n = set_child_n,
    insert_child_n = insert_child_n,
    remove_child_n = remove_child_n,

    set_valign = set_valign,
    set_halign = set_halign,
    set_padding = set_padding,
}

