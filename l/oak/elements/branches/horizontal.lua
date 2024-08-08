
local tt_table = require("terra.tools.table")

local to_padding = require("terra.oak.padding")
local to_size = require("terra.oak.size")
local to_align = require("terra.oak.align")
local to_border = require("terra.oak.border")
local to_internal = require("terra.oak.internal")

local toe_internal = require("terra.oak.elements.internal")
local toe_element = require("terra.oak.elements.element")

local toeb_branch = require("terra.oak.elements.branches.branch")
local toeb_internal = require("terra.oak.elements.branches.internal")

local function horizontal_calculate_minimum_dimensions(branch, constraint_w, constraint_h)

    local spacing = branch.spacing or 0
    local standardized_padding = to_padding.standardize(branch.padding or 0)
    local el_bw = to_border.get_width(branch)

    local acc_w =
        standardized_padding.left +
        standardized_padding.right +
        toeb_internal.get_spacing_between_children(#branch, spacing)
        + (el_bw * 2)
    local min_h = standardized_padding.top + standardized_padding.bottom + (el_bw * 2)
    local max_h = 0

    -- NOTE: only go through the children in the array portion of the table because
    -- we don't want the shadow or the bg to take up horizontal space
    for _, child in ipairs(branch) do
        -- NOTE: child_min_w and child_min_h already includes the border width
        local child_border_width = to_border.get_width(child)
        local child_standardized_padding = to_padding.standardize(child.padding or 0)
        local child_w, child_h = child.width, child.height
        if type(child_w) == "number" and type(child_h) == "number" then
            acc_w = acc_w
                + child_w
                + (child_border_width * 2)
                + child_standardized_padding.left
                + child_standardized_padding.right
            max_h = math.max(
                max_h,
                child_h
                    + (child_border_width * 2)
                    + child_standardized_padding.top
                    + child_standardized_padding.bottom
            )
        elseif type(child_w) == "number" and type(child_h) ~= "number" then
            local _, child_min_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            acc_w = acc_w
                + child_w
                + (child_border_width * 2)
                + child_standardized_padding.left
                + child_standardized_padding.right
            max_h = math.max(max_h, child_min_h)
        elseif type(child_w) ~= "number" and type(child_h) == "number" then
            local child_min_w, _ = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            acc_w = acc_w + child_min_w
            max_h = math.max(
                max_h,
                child_h
                    + (child_border_width * 2)
                    + child_standardized_padding.top
                    + child_standardized_padding.bottom
            )
        else -- both are not numbers
            local child_min_w, child_min_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            acc_w = acc_w + child_min_w
            max_h = math.max(max_h, child_min_h)
        end
    end

    return acc_w, min_h + max_h
end


local function horizontal_dimensionate_children(branch, avail_w, avail_h)

    local spacing = branch.spacing or 0

    -- account for padding and spacing
    -- NOTE: use #branch instead of #all_children because we don't want chlidren
    -- like the bg and shadow to be part of horizontal layout
    local total_spacing = toeb_internal.get_spacing_between_children(#branch, spacing)

    local standardized_padding = to_padding.standardize(branch.padding or 0)
    local padding_top = standardized_padding.top
    local padding_right = standardized_padding.right
    local padding_bottom = standardized_padding.bottom
    local padding_left = standardized_padding.left
    local parent_bw = to_border.get_width(branch)

    local dimensionated_children_data = {
        available_width = avail_w,
        available_height = avail_h,
        spacing = spacing,
        standardized_padding = standardized_padding,
        parent_border_width = parent_bw,
    }

    do
        local shadow = branch.shadow
        local bg = branch.bg

        if shadow ~= nil then dimensionated_children_data.shadow = shadow end
        if bg ~= nil then dimensionated_children_data.bg = bg end
    end

    -- NOTE: use ipairs(branch) so we dont layout horizontally bg and shadow
    for k, child in ipairs(branch) do
        dimensionated_children_data[k] = {
            valign = child.valign or to_align.TOP,
            offset_x = child.offset_x or 0,
            offset_y = child.offset_y or 0,
            element = child,
        }
    end

    local number_width_children = {}
    local shrink_width_children = {}
    local fill_width_children_number = 0 -- for dividing width evenly later
    local fill_width_children = {}
    -- for width-fill children, the first priority is their borders.
    -- so we'll have to do subtract the total border width from the remaining
    -- width to find out how much we have left for width-fill elements
    local fill_width_children_total_border_width = 0

    local last_halign_left_child_i = nil
    local halign_left_children = {}
    local halign_center_child_data = nil
    local halign_right_children = {}

    -- divide up the children. we need this because we need to first get
    -- the dimensions of the number-width children and shrink-width children,
    -- to know the remaining width (if any) to distribute to the width="fill"
    -- widgets. we also get the raw height information of children to use later
    -- note: in order to optimise this later, we store the elements in contiguous
    -- arrays, but we also keep track of the initial index of the element, so we
    -- can put them back together at the index they came from
    for k, child in ipairs(branch) do
        -- NOTE: use ipairs(branch) so we dont layout horizontally bg and shadow

        local raw_child_w = child.width
        if type(raw_child_w) == "number" then
            table.insert(number_width_children, {k, child})
        elseif to_size.is_fill(raw_child_w) then
            table.insert(fill_width_children, {k, child})
            fill_width_children_number = fill_width_children_number + 1
            fill_width_children_total_border_width =
                fill_width_children_total_border_width + (to_border.get_width(child) * 2)
        else -- raw_child_w == size.shrink then
            table.insert(shrink_width_children, {k, child})
        end

        if child.halign == to_align.RIGHT then
            table.insert(halign_right_children, {k, child})
        elseif child.halign == to_align.CENTER then
            if halign_center_child_data == nil then
                halign_center_child_data = {k, child}
            else
                -- if we already have a halign="center" element, we treat all other elements as though
                -- they have halign = "right" because what the hell are you doing putting multiple elements
                -- with halign="center" into your layout on the same level. fix your layout
                table.insert(halign_right_children, {k, child})
            end
        -- if it has no "halign", we treat it as halign = "left"
        else -- child.halign == align.left then
            table.insert(halign_left_children, {k, child})
            last_halign_left_child_i = k
        end
    end

    -- now that we have the children divided up in their appropriate
    -- categories, we can start calculating their dimensions

    -- we ll need this to calculate the fill width children
    local occupied_width =
        total_spacing
        + padding_left
        + padding_right
        + (parent_bw * 2)
        + fill_width_children_total_border_width

    -- process width for children that already have it explicitly specified
    for _, child_data in ipairs(number_width_children) do
        local original_child_i = child_data[1]
        local child = child_data[2]
        local child_bw = to_border.get_width(child)
        local child_width = child.width
        dimensionated_children_data[original_child_i].width = child_width + (child_bw * 2)
        occupied_width = occupied_width + child_width + (child_bw * 2)
    end

    -- now figure width for children that have width = "shrink"
    for _, child_data in ipairs(shrink_width_children) do
        local original_child_i = child_data[1]
        local child = child_data[2]
        local child_bw = to_border.get_width(child)
        -- border width is already calculated inside `oak_calculate_minimum_dimensions`
        local constraint_height = nil
        if type(child.height) == "number" then
            constraint_height = child.height
        elseif to_size.is_fill(child.height) then
            constraint_height = math.max(avail_h - (padding_top + padding_bottom), child_bw * 2)
        end
        local min_w, _ = child:oak_calculate_minimum_dimensions(nil, constraint_height)
        dimensionated_children_data[original_child_i].width = min_w
        occupied_width = occupied_width + min_w
    end

    -- finally, go through the children with width="fill".
    -- we do this last because only now we know the remaining width (if any) and
    -- can divide it equally between children
    local remaining_width = avail_w - occupied_width
    if remaining_width > 0 then
        local safe_divide_by = math.max(fill_width_children_number, 1) -- dont divide by 0
        local equally_divided_remaining_width = remaining_width / safe_divide_by
        for _, child_data in ipairs(fill_width_children) do
            local original_child_ind = child_data[1]
            local child_bw = to_border.get_width(child_data[2])
            dimensionated_children_data[original_child_ind].width =
                equally_divided_remaining_width
                    + (child_bw * 2)
        end
    else
        for _, child_data in ipairs(fill_width_children) do
            local original_child_ind = child_data[1]
            local child_bw = to_border.get_width(child_data[2])
            -- yes, the element doesn't have enough width to render its content,
            -- but we do render its border
            dimensionated_children_data[original_child_ind].width =
                (child_bw * 2)
        end
    end

    -- calculate the height of children after the width because only now do
    -- we know what the constraint_width is in case the child has width-shrink
    -- or width-fill
    -- NOTE: use ipairs(branch) so we dont layout bg and shadow
    for k, child in ipairs(branch) do
        local real_child_h = 0
        local child_bw = to_border.get_width(child)
        if type(child.height) == "number" then
            real_child_h = child.height + (child_bw * 2)
        elseif to_size.is_shrink(child.height) then
            -- minimum dimension result already includes the border_width
            local constraint_width = nil
            if type(child.width) == "number" then
                constraint_width = child.width
            elseif to_size.is_fill(child.width) then
                constraint_width = dimensionated_children_data[k].width
            end
            local _, min_h = child:oak_calculate_minimum_dimensions(constraint_width, nil)
            real_child_h = min_h
        else -- child.height == "fill"
            real_child_h = math.max(avail_h - (padding_top + padding_bottom), child_bw * 2)
        end
        dimensionated_children_data[k].height = real_child_h
    end


    if #fill_width_children > 0 then
        -- we have a width-fill element which means an easy layout.
        -- we know we can't center-align or right-align any elements, so
        -- we just align all elements as though they all had halign = "left"
        dimensionated_children_data.position_type = toeb_internal.POSITION_START
        return dimensionated_children_data
    end

    if remaining_width <= 0 then
        dimensionated_children_data.position_type = toeb_internal.POSITION_START
        return dimensionated_children_data
    end

    local first_halign_right_child_i
    local first_halign_right_child_data = halign_right_children[1]
    do
        if first_halign_right_child_data ~= nil then
            first_halign_right_child_i = first_halign_right_child_data[1]
        end
    end

    if first_halign_right_child_i == 1 then
        -- if the first halign-right element has index 1, that means all 
        -- elements get pushed to the right
        dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
        dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
        return dimensionated_children_data
    end

    if halign_center_child_data == nil then -- no center element
        if first_halign_right_child_data == nil then
            dimensionated_children_data.position_type = toeb_internal.POSITION_START
            return dimensionated_children_data
        end

        dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
        dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
        return dimensionated_children_data
    end


    -- if we're here, we have :
    -- 1. some remaining width
    -- 2. no fill width children
    -- 3. a halign-center element
    -- now we have to see if we can center-align or right-align elements that
    -- want it
    local halign_center_child_i = halign_center_child_data[1]
    if last_halign_left_child_i ~= nil and first_halign_right_child_i ~= nil then

        if last_halign_left_child_i < halign_center_child_i and
            halign_center_child_i < first_halign_right_child_i
        then
            -- if we're on this if branch there's nothing blocking the
            -- path of the center element from being put in the middle,
            -- but now we need to see if any elements are bleeding over it

            local halign_left_children_width = 0
            for i = 1, last_halign_left_child_i do
                halign_left_children_width = halign_left_children_width
                    + dimensionated_children_data[i].width
            end

            local halign_right_children_width = 0
            for i = first_halign_right_child_i, #dimensionated_children_data do
                halign_right_children_width = halign_right_children_width
                    + dimensionated_children_data[i].width
            end

            local spacing_left_side = spacing * (halign_center_child_i - 1)
            local spacing_right_side = spacing * (#dimensionated_children_data - (first_halign_right_child_i - 1))

            local center_child_width = dimensionated_children_data[halign_center_child_i].width
            local ideal_center_x = (avail_w - center_child_width) / 2

            if padding_left
                + parent_bw
                + spacing_left_side
                + halign_left_children_width
                < ideal_center_x
            then
                if padding_right
                    + parent_bw
                    + spacing_right_side
                    + halign_right_children_width
                    < avail_w - (ideal_center_x + center_child_width)
                then
                    -- elements on the left and elements on the right don't push over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.halign_center_child_id = halign_center_child_i
                    dimensionated_children_data.center_element_x = ideal_center_x
                else
                    -- elements on the right push over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_halign_right_child_id = halign_center_child_i
                end
            else
                -- elements on the left push over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
            end
        else
            -- in all other cases we just halign-right all elements past the first
            -- halign-right element because halign-right elements have highest priority
            dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
            dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
        end

    elseif last_halign_left_child_i ~= nil
        and first_halign_right_child_data == nil
    then -- we have left-align elements, and a center element

        if last_halign_left_child_i < halign_center_child_i then
            -- now we need to see if the left-align elements bleed
            -- over the center element

            local halign_left_children_width = 0
            for i = 1, halign_center_child_i - 1 do
                halign_left_children_width = halign_left_children_width
                    + dimensionated_children_data[i].width
            end

            local spacing_left_side = spacing * (halign_center_child_i - 1)

            local center_child_width = dimensionated_children_data[halign_center_child_i].width
            local ideal_center_x = (avail_w - center_child_width) / 2

            if padding_left
                + parent_bw
                + spacing_left_side
                + halign_left_children_width
                < ideal_center_x
            then
                if padding_right
                    + parent_bw
                    < avail_w - (ideal_center_x + center_child_width)
                then
                    -- nothing pushes or bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.halign_center_child_id = halign_center_child_i
                    dimensionated_children_data.center_element_x = ideal_center_x
                else
                    -- padding on the right pushes over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_halign_right_child_id = halign_center_child_i
                end
            else
                -- elements on the left push over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
            end
        else -- the center-align element is pushed by a left-align element
            -- everything goes to the left
            dimensionated_children_data.position_type = toeb_internal.POSITION_START
        end

    elseif last_halign_left_child_i == nil and
        first_halign_right_child_data ~= nil
    then -- we have right-align elements and a center element

        if halign_center_child_i < first_halign_right_child_i then
            -- now we need to see if the right-align elements bleed
            -- over the center element

            local halign_right_children_width = 0
            for i = first_halign_right_child_i, #dimensionated_children_data do
                halign_right_children_width = halign_right_children_width
                    + dimensionated_children_data[i].width
            end

            local spacing_right_side = spacing * (#dimensionated_children_data - (first_halign_right_child_i - 1))

            local center_child_width = dimensionated_children_data[halign_center_child_i].width
            local ideal_center_x = (avail_w - center_child_width) / 2

            if padding_left
                + parent_bw
                < ideal_center_x
            then
                if padding_right
                    + parent_bw
                    + spacing_right_side
                    + halign_right_children_width
                    < avail_w - (ideal_center_x + center_child_width)
                then
                    -- nothing pushes or bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.halign_center_child_id = halign_center_child_i
                    dimensionated_children_data.center_element_x = ideal_center_x
                else
                    -- elements on the right bleed over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_halign_right_child_id = halign_center_child_i
                end
            else
                -- padding on the left bleeds over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
            end
        else -- the center element is pushed by a right-align element
            -- so everything goes to the right
            dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
            dimensionated_children_data.first_halign_right_child_id = first_halign_right_child_i
        end

    else -- there's only the center element

        local center_child_width = dimensionated_children_data[halign_center_child_i].width
        local ideal_center_x = (avail_w - center_child_width) / 2

        dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
        dimensionated_children_data.halign_center_child_id = halign_center_child_i
        dimensionated_children_data.center_element_x = ideal_center_x
    end

    return dimensionated_children_data
end


local function horizontal_position_children(dimensionated_children_data)

    local available_width = dimensionated_children_data.available_width
    local available_height = dimensionated_children_data.available_height
    local spacing = dimensionated_children_data.spacing
    local parent_bw = dimensionated_children_data.parent_border_width
    local padding_top, padding_right, padding_bottom, padding_left
    do
        local standardized_padding = dimensionated_children_data.standardized_padding
        padding_top = standardized_padding.top
        padding_right = standardized_padding.right
        padding_bottom = standardized_padding.bottom
        padding_left = standardized_padding.left
    end

    local positioned_children_data = {}

    do
        -- normally, elements should not be dimensionated here. only positioned.
        -- but it's such a trivial task that we just dimensionate and position 
        -- the shadow and bg here

        local shadow = dimensionated_children_data.shadow
        if shadow ~= nil then
            table.insert(positioned_children_data, toe_internal.shadow_dimensionate_and_position(
                shadow,
                available_width,
                available_height
            ))
        end

        local bg = dimensionated_children_data.bg
        if bg ~= nil then
            table.insert(positioned_children_data, {
                x = bg.offset_x or 0,
                y = bg.offset_y or 0,
                width = available_width,
                height = available_height,
                element = bg,
            })
        end
    end

    local position_type = dimensionated_children_data.position_type

    if position_type == toeb_internal.POSITION_START_CENTER_END then

        local halign_center_child_id = dimensionated_children_data.halign_center_child_id
        local center_child_x = dimensionated_children_data.center_element_x

        -- left-halign elements
        local left_side_acc_x = padding_left + parent_bw
        for i=1, halign_center_child_id - 1 do

            local child = dimensionated_children_data[i]
            local child_y = to_internal.align_on_secondary_axis(
                padding_top + parent_bw,
                padding_bottom + parent_bw,
                child.valign,
                available_height,
                child.height
            )
            table.insert(positioned_children_data, {
                x = child.offset_x + left_side_acc_x,
                y = child.offset_y + child_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            left_side_acc_x = left_side_acc_x + child.width + spacing
        end

        -- center element
        local center_child = dimensionated_children_data[halign_center_child_id]
        local center_child_y = to_internal.align_on_secondary_axis(
            padding_top + parent_bw,
            padding_bottom + parent_bw,
            center_child.valign,
            available_height,
            center_child.height
        )
        table.insert(positioned_children_data, {
            x = center_child.offset_x + center_child_x,
            y = center_child.offset_y + center_child_y,
            width = center_child.width,
            height = center_child.height,
            element = center_child.element
        })

        -- right elements (if there are any)
        if halign_center_child_id ~= #dimensionated_children_data then
            local right_side_acc_x = available_width - (padding_right + parent_bw)
            for i=#dimensionated_children_data, (halign_center_child_id + 1), -1 do
                local child = dimensionated_children_data[i]
                local child_y = to_internal.align_on_secondary_axis(
                    padding_top + parent_bw,
                    padding_bottom + parent_bw,
                    child.valign,
                    available_height,
                    child.height
                )

                right_side_acc_x = right_side_acc_x - child.width

                table.insert(positioned_children_data, {
                    x = child.offset_x + right_side_acc_x,
                    y = child.offset_y + child_y,
                    width = child.width,
                    height = child.height,
                    element = child.element,
                })

                right_side_acc_x = right_side_acc_x - spacing
            end
        end

    elseif position_type == toeb_internal.POSITION_START_END then
        local first_halign_right_child_id = dimensionated_children_data.first_halign_right_child_id

        -- left-halign elements
        local left_side_acc_x = padding_left + parent_bw
        for i=1, first_halign_right_child_id - 1 do
            local child = dimensionated_children_data[i]
            local child_y = to_internal.align_on_secondary_axis(
                padding_top + parent_bw,
                padding_bottom + parent_bw,
                child.valign,
                available_height,
                child.height
            )

            table.insert(positioned_children_data, {
                x = child.offset_x + left_side_acc_x,
                y = child.offset_y + child_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            left_side_acc_x = left_side_acc_x + child.width + spacing
        end

        -- right-halign elements
        local right_side_acc_x = available_width - (padding_right + parent_bw)
        for i=#dimensionated_children_data, first_halign_right_child_id, -1 do
            local child = dimensionated_children_data[i]
            local child_y = to_internal.align_on_secondary_axis(
                padding_top + parent_bw,
                padding_bottom + parent_bw,
                child.valign,
                available_height,
                child.height
            )

            right_side_acc_x = right_side_acc_x - child.width

            table.insert(positioned_children_data, {
                x = child.offset_x + right_side_acc_x,
                y = child.offset_y + child_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            right_side_acc_x = right_side_acc_x - spacing
        end
    else -- position_type == toeb_internal.POSITION_START
        local left_side_acc_x = padding_left + parent_bw

        for i=1, #dimensionated_children_data do
            local child = dimensionated_children_data[i]
            local child_y = to_internal.align_on_secondary_axis(
                padding_top + parent_bw,
                padding_bottom + parent_bw,
                child.valign,
                available_height,
                child.height
            )

            table.insert(positioned_children_data, {
                x = child.offset_x + left_side_acc_x,
                y = child.offset_y + child_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            left_side_acc_x = left_side_acc_x + child.width + spacing
        end

    end

    return positioned_children_data
end

-- TODO: turn this into a single function
local function horizontal_geometrize_children(branch, avail_w, avail_h)

    -- NOTE: this will return nil if this branch has no shadow, no bg,
    -- and no sub-children
    if #branch:oak_get_children() == 0 then return nil end

    return horizontal_position_children(
        horizontal_dimensionate_children(branch, avail_w, avail_h)
    )
end

local function new(args)
    if args == nil then args = {} end

    local horizontal_defaults = {

        -- part of the interface to be a <terra.oak.elements.branch>
        oak_geometrize_children = horizontal_geometrize_children,
        oak_calculate_minimum_dimensions = horizontal_calculate_minimum_dimensions,

        -- only horizontal and vertical branches can have spacing
        set_spacing = toeb_internal.set_spacing,
    }

    return tt_table.crush(toeb_branch.new(), horizontal_defaults, args)
end

return {
    new = new,

    dimensionate_children = horizontal_dimensionate_children,
    position_children = horizontal_position_children,

    oak_geometrize_children = horizontal_geometrize_children,
    oak_calculate_minimum_dimensions = horizontal_calculate_minimum_dimensions,
}

