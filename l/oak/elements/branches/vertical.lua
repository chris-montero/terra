
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

local function vertical_calculate_minimum_dimensions(vertical, constraint_w, constraint_h)

    local spacing = vertical.spacing or 0
    local standardized_padding = to_padding.standardize(vertical.padding or 0)
    local el_bw = to_border.get_width(vertical)

    local acc_h =
        standardized_padding.top +
        standardized_padding.bottom +
        toeb_internal.get_spacing_between_children(#vertical, spacing)
        + (el_bw * 2)
    local min_w = standardized_padding.left + standardized_padding.right + (el_bw * 2)
    local max_w = 0

    -- NOTE: only go through the children in the array portion of the table because
    -- we don't want the shadow or the bg to take up horizontal space
    for _, child in ipairs(vertical) do

        local child_border_width = to_border.get_width(child)
        local child_standardized_padding = to_padding.standardize(child.padding or 0)
        local child_w, child_h = child.width, child.height

        if type(child_w) == "number" and type(child_h) == "number" then
            max_w = math.max(
                max_w,
                child_w
                    + (child_border_width * 2)
                    + child_standardized_padding.left
                    + child_standardized_padding.right
            )
            acc_h = acc_h
                + child_h
                + (child_border_width * 2)
                + child_standardized_padding.top
                + child_standardized_padding.bottom
        elseif type(child_w) == "number" and type(child_h) ~= "number" then
            local _, child_min_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(
                max_w,
                child_w
                    + (child_border_width * 2)
                    + child_standardized_padding.left
                    + child_standardized_padding.right
            )
            acc_h = acc_h + child_min_h
        elseif type(child_w) ~= "number" and type(child_h) == "number" then
            local child_min_w, _ = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(max_w, child_min_w)
            acc_h = acc_h
                + child_h
                + (child_border_width * 2)
                + child_standardized_padding.top
                + child_standardized_padding.bottom
        else -- both are not numbers
            local child_min_w, child_min_h = child:oak_calculate_minimum_dimensions(constraint_w, constraint_h)
            max_w = math.max(max_w, child_min_w)
            acc_h = acc_h + child_min_h
        end
    end

    return min_w + max_w, acc_h
end

local function vertical_dimensionate_children(vertical, avail_w, avail_h)

    local spacing = vertical.spacing or 0

    -- account for padding and spacing
    local total_spacing = toeb_internal.get_spacing_between_children(#vertical, spacing)
    local standardized_padding = to_padding.standardize(vertical.padding or 0)
    local padding_top = standardized_padding.top
    local padding_right = standardized_padding.right
    local padding_bottom = standardized_padding.bottom
    local padding_left = standardized_padding.left
    local parent_bw = to_border.get_width(vertical)

    local dimensionated_children_data = {
        available_width = avail_w,
        available_height = avail_h,
        spacing = spacing,
        standardized_padding = standardized_padding,
        parent_border_width = parent_bw,
    }

    do
        local shadow = vertical.shadow
        local bg = vertical.bg
        if shadow ~= nil then dimensionated_children_data.shadow = shadow end
        if bg ~= nil then dimensionated_children_data.bg = bg end
    end

    -- NOTE: use ipairs(vertical) so we dont layout vertically bg and shadow
    for k, child in ipairs(vertical) do
        dimensionated_children_data[k] = {
            halign = child.halign or to_align.LEFT,
            offset_x = child.offset_x or 0,
            offset_y = child.offset_y or 0,
            element = child,
        }
    end

    local number_height_children = {}
    local shrink_height_children = {}
    local fill_height_children_number = 0 -- for dividing height evenly later
    local fill_height_children = {}
    -- for height-fill children, the first priority is their borders.
    -- so we'll have to do subtract the total border width from the remaining
    -- height to find out how much we have left for height-fill elements
    local fill_height_children_total_border_width = 0

    local last_valign_top_child_i = nil
    local valign_top_children = {}
    local valign_center_child_data = nil
    local valign_bottom_children = {}

    -- divide up the children. we need this because we need to first get
    -- the dimensions of the number-height children and shrink-height children,
    -- to know the remaining height (if any) to distribute to the height="fill"
    -- widgets we also get the raw height information of children to use later
    -- note: in order to optimise this later, we store the elements in contiguous
    -- arrays, but we also keep track of the initial index of the element
    -- NOTE: use ipairs(vertical) so we dont layout horizontally bg and shadow
    for k, child in ipairs(vertical) do
        local raw_child_h = child.height
        if type(raw_child_h) == "number" then
            table.insert(number_height_children, {k, child})
        elseif to_size.is_fill(raw_child_h) then
            table.insert(fill_height_children, {k, child})
            fill_height_children_number = fill_height_children_number + 1
            fill_height_children_total_border_width =
                fill_height_children_total_border_width + (to_border.get_width(child) * 2)
        else -- raw_child_h == size.shrink then
            table.insert(shrink_height_children, {k, child})
        end

        if child.valign == to_align.BOTTOM then
            table.insert(valign_bottom_children, {k, child})
        elseif child.valign == to_align.CENTER then
            if valign_center_child_data == nil then
                valign_center_child_data = {k, child}
            else
                -- if we already have a valign="center" element, we treat all other elements as though
                -- they have valign = "bottom" because what the hell are you doing putting multiple elements
                -- with valign="center" into your layout on the same level. fix your layout
                table.insert(valign_bottom_children, {k, child})
            end
        -- if it has no "valign", we treat it as valign = "top"
        else -- child.valign == align.top then
            table.insert(valign_top_children, {k, child})
            last_valign_top_child_i = k
        end
    end

    -- now that we have the children divided up in their appropriate
    -- categories, we can start calculating their dimensions

    -- we ll need this to calculate the fill height children
    local occupied_height =
        total_spacing
        + padding_top
        + padding_bottom
        + (parent_bw * 2)
        + fill_height_children_total_border_width

    -- process height for children that already have it explicitly specified
    -- NOTE: use ipairs(vertical) so we dont layout horizontally bg and shadow
    for _, child_data in ipairs(number_height_children) do
        local original_child_i = child_data[1]
        local child = child_data[2]
        local child_height = child.height
        local child_bw = to_border.get_width(child)
        dimensionated_children_data[original_child_i].height = child_height + (child_bw * 2)
        occupied_height = occupied_height + child_height + (child_bw * 2)
    end

    -- now figure height for children that have height = "shrink"
    for _, child_data in ipairs(shrink_height_children) do
        local original_child_i = child_data[1]
        local child = child_data[2]
        local child_bw = to_border.get_width(child)
        -- border width is already calculated inside `oak_calculate_minimum_dimensions`
        local constraint_width = nil
        if type(child.width) == "number" then
            constraint_width = child.width
        elseif to_size.is_fill(child.width) then
            constraint_width = math.max(avail_w - (padding_left + padding_right), child_bw * 2)
        end
        local _, min_h = child:oak_calculate_minimum_dimensions(constraint_width, nil)
        dimensionated_children_data[original_child_i].height = min_h
        occupied_height = occupied_height + min_h
    end

    -- finally, go through the children with height="fill".
    -- we do this last because only now we know the remaining height and
    -- can divide it equally between children
    local remaining_height = avail_h - occupied_height
    if remaining_height > 0 then
        local safe_divide_by = math.max(fill_height_children_number, 1)
        -- this equally divided remaining height actually has the borders of each
        -- child accounted for. This means that this value refers to the available
        -- height of the CONTENT of these height-fill elements
        local equally_divided_remaining_height = remaining_height / safe_divide_by -- dont divide by 0
        for _, child_data in ipairs(fill_height_children) do
            local original_child_ind = child_data[1]
            local child_bw = to_border.get_width(child_data[2])
            dimensionated_children_data[original_child_ind].height =
                equally_divided_remaining_height
                    + (child_bw * 2)
        end
    else
        for _, child_data in ipairs(fill_height_children) do
            local original_child_ind = child_data[1]
            local child_bw = to_border.get_width(child_data[2])
            -- yes, the element doesn't have enough height to render its content,
            -- but we do render its borders
            dimensionated_children_data[original_child_ind].height = (child_bw * 2)
        end
    end

    -- calculate the width of elements because this is the same procedure for 
    -- all children. also, we need to do this afterwards because only now we 
    -- know the constraint_height to give to children that have width-shrink

    -- NOTE: use ipairs(vertical) so we dont layout bg and shadow
    for k, child in ipairs(vertical) do
        local real_child_w = 0
        local child_bw = to_border.get_width(child)
        if type(child.width) == "number" then
            real_child_w = child.width + (child_bw * 2)
        elseif to_size.is_shrink(child.width) then
            -- minimum dimension result already includes the border_width
            local constraint_height = nil
            if type(child.height) == "number" then
                constraint_height = child.height
            elseif to_size.is_fill(child.height) then
                constraint_height = dimensionated_children_data[k].height
            end
            local min_w, _ = child:oak_calculate_minimum_dimensions(nil, constraint_height)
            real_child_w = min_w
        else -- child.width == "fill"
            real_child_w = math.max(avail_w - (padding_left + padding_right), child_bw * 2)
        end
        dimensionated_children_data[k].width = real_child_w
    end


    if #fill_height_children > 0 then
        -- we have a height-fill element which means an easy layout.
        -- we know we can't center-align or bottom-align any elements, so
        -- we just align all elements as though they all had valign = "top"
        dimensionated_children_data.position_type = toeb_internal.POSITION_START
        return dimensionated_children_data
    end

    if remaining_height <= 0 then
        dimensionated_children_data.position_type = toeb_internal.POSITION_START
        return dimensionated_children_data
    end

    local first_valign_bottom_child_i
    local first_valign_bottom_child_data = valign_bottom_children[1]
    do
        if first_valign_bottom_child_data ~= nil then
            first_valign_bottom_child_i = first_valign_bottom_child_data[1]
        end
    end

    if first_valign_bottom_child_i == 1 then
        -- valign bottom has highest priority, so everything goes to the bottom
        dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
        dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
    end

    if valign_center_child_data == nil then -- no center element
        if first_valign_bottom_child_data == nil then
            dimensionated_children_data.position_type = toeb_internal.POSITION_START
            return dimensionated_children_data
        end

        dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
        dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
        return dimensionated_children_data
    end


    -- if we're here, we have :
    -- 1. some remaining width
    -- 2. no fill height children
    -- 3. a valign-center element
    -- now we have to see if we can center-align or bottom-align elements that
    -- want it
    local valign_center_child_i = valign_center_child_data[1]
    if last_valign_top_child_i ~= nil and first_valign_bottom_child_i ~= nil then

        if last_valign_top_child_i < valign_center_child_i and
            valign_center_child_i < first_valign_bottom_child_i
        then
            -- if we're on this "if" branch there's nothing blocking the
            -- path of the center element from being put in the middle,
            -- but now we need to see if any elements are bleeding over it

            local valign_top_children_height = 0
            for i = 1, last_valign_top_child_i do
                valign_top_children_height = valign_top_children_height
                    + dimensionated_children_data[i].height
            end

            local valign_bottom_children_height = 0
            for i = first_valign_bottom_child_i, #dimensionated_children_data do
                valign_bottom_children_height = valign_bottom_children_height
                    + dimensionated_children_data[i].height
            end

            local spacing_top_side = spacing * (valign_center_child_i - 1)
            local spacing_bottom_side = spacing * (#dimensionated_children_data - first_valign_bottom_child_i)

            local center_child = dimensionated_children_data[valign_center_child_i]
            local ideal_center_y = (avail_h - center_child.height) / 2

            if padding_top
                + parent_bw
                + spacing_top_side
                + valign_top_children_height
                < ideal_center_y
            then
                if padding_bottom
                    + parent_bw
                    + spacing_bottom_side
                    + valign_bottom_children_height
                    < avail_h - (ideal_center_y + center_child.height)
                then
                    -- nothing pushes or bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.valign_center_child_id = valign_center_child_i
                    dimensionated_children_data.center_element_y = ideal_center_y
                else
                    -- elements on the bottom push over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_valign_bottom_child_id = valign_center_child_i
                end
            else
                -- elements on the top push over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
            end
        else
            -- in all other cases we just valign-bottom all elements past the first
            -- valign-bottom element because valign-bottom elements have highest priority
            dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
            dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
        end

    elseif last_valign_top_child_i ~= nil and
        first_valign_bottom_child_i == nil
    then -- we only have top-align elements and a center element

        if last_valign_top_child_i < valign_center_child_i then
            -- now we need to see if the top-align elements bleed 
            -- over the center element

            local valign_top_children_height = 0
            for i = 1, last_valign_top_child_i do
                valign_top_children_height = valign_top_children_height
                    + dimensionated_children_data[i].height
            end

            local spacing_top_side = spacing * (valign_center_child_i - 1)

            local center_child = dimensionated_children_data[valign_center_child_i]
            local ideal_center_y = (avail_h - center_child.height) / 2

            if padding_top
                + parent_bw
                + spacing_top_side
                + valign_top_children_height
                < ideal_center_y
            then
                if padding_bottom
                    + parent_bw
                    < avail_h - (ideal_center_y + center_child.height)
                then -- nothing pushes or bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.valign_center_child_id = valign_center_child_i
                    dimensionated_children_data.center_element_y = ideal_center_y
                else -- padding on the bottom bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_valign_bottom_child_id = valign_center_child_i
                end
            else -- elements on the top bleed over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
            end
        else -- the center-align element is pushed by a top-align element
            -- everything goes to the left
            dimensionated_children_data.position_type = toeb_internal.POSITION_START
        end

    elseif last_valign_top_child_i == nil and
        first_valign_bottom_child_i ~= nil
    then -- we have bottom-align elements and a center element

        if valign_center_child_i < first_valign_bottom_child_i then
            -- now we need to see if the bottom-align elements bleed
            -- over the center element

            local valign_bottom_children_height = 0
            for i = first_valign_bottom_child_i, #dimensionated_children_data do
                valign_bottom_children_height = valign_bottom_children_height
                    + dimensionated_children_data[i].height
            end

            local spacing_bottom_side = spacing * (#dimensionated_children_data - first_valign_bottom_child_i)

            local center_child = dimensionated_children_data[valign_center_child_i]
            local ideal_center_y = (avail_h - center_child.height) / 2

            if padding_top
                + parent_bw
                < ideal_center_y
            then
                if padding_bottom
                    + parent_bw
                    + spacing_bottom_side
                    + valign_bottom_children_height
                    < avail_h - (ideal_center_y + center_child.height)
                then
                    -- nothing pushes or bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
                    dimensionated_children_data.valign_center_child_id = valign_center_child_i
                    dimensionated_children_data.center_element_y = ideal_center_y
                else
                    -- elements on the bottom bleeds over the center element
                    dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                    dimensionated_children_data.first_valign_bottom_child_id = valign_center_child_i
                end
            else
                -- padding on the top bleeds over the center element
                dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
                dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
            end
        else -- the center element is pushed by a bottom-align element
            -- so everything goes to the bottom
            dimensionated_children_data.position_type = toeb_internal.POSITION_START_END
            dimensionated_children_data.first_valign_bottom_child_id = first_valign_bottom_child_i
        end

    else -- there's only the center element

        local center_child = dimensionated_children_data[valign_center_child_i]
        local ideal_center_y = (avail_h - center_child.height) / 2

        dimensionated_children_data.position_type = toeb_internal.POSITION_START_CENTER_END
        dimensionated_children_data.valign_center_child_id = valign_center_child_i
        dimensionated_children_data.center_element_y = ideal_center_y
    end

    return dimensionated_children_data
end

local function vertical_position_children(dimensionated_children_data)

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
            table.insert(positioned_children_data, toeb_internal.shadow_dimensionate_and_position(
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
                element = bg
            })
        end
    end

    local position_type = dimensionated_children_data.position_type

    if position_type == toeb_internal.POSITION_START_CENTER_END then

        local valign_center_child_id = dimensionated_children_data.valign_center_child_id
        local center_child_y = dimensionated_children_data.center_element_y

        -- top-valign elements
        local top_side_acc_y = padding_top + parent_bw
        for i=1, valign_center_child_id - 1 do
            local child = dimensionated_children_data[i]
            local child_x = to_internal.align_on_secondary_axis(
                padding_left + parent_bw,
                padding_right + parent_bw,
                child.halign,
                available_width,
                child.width
            )

            table.insert(positioned_children_data, {
                x = child.offset_x + child_x,
                y = child.offset_y + top_side_acc_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            top_side_acc_y = top_side_acc_y + child.height + spacing
        end

        -- center element
        local center_child = dimensionated_children_data[valign_center_child_id]
        local center_child_x = to_internal.align_on_secondary_axis(
            padding_left + parent_bw,
            padding_right + parent_bw,
            center_child.halign,
            available_width,
            center_child.width
        )
        table.insert(positioned_children_data, {
            x = center_child.offset_x + center_child_x,
            y = center_child.offset_y + center_child_y,
            width = center_child.width,
            height = center_child.height,
            element = center_child.element
        })

        -- bottom elements (if there are any)
        if valign_center_child_id ~= #dimensionated_children_data then
            local bottom_side_acc_y = available_height - (padding_bottom + parent_bw)
            for i=#dimensionated_children_data, (valign_center_child_id + 1), -1 do
                local child = dimensionated_children_data[i]
                local child_x = to_internal.align_on_secondary_axis(
                    padding_left + parent_bw,
                    padding_right + parent_bw,
                    child.halign,
                    available_width,
                    child.width
                )

                bottom_side_acc_y = bottom_side_acc_y - child.height

                table.insert(positioned_children_data, {
                    x = child.offset_x + child_x,
                    y = child.offset_y + bottom_side_acc_y,
                    width = child.width,
                    height = child.height,
                    element = child.element,
                })

                bottom_side_acc_y = bottom_side_acc_y - spacing
            end
        end

    elseif position_type == toeb_internal.POSITION_START_END then

        local first_valign_bottom_child_id = dimensionated_children_data.first_valign_bottom_child_id

        -- top-valign elements
        local top_side_acc_y = padding_top + parent_bw
        for i=1, first_valign_bottom_child_id - 1 do
            local child = dimensionated_children_data[i]
            local child_x = to_internal.align_on_secondary_axis(
                padding_left + parent_bw,
                padding_right + parent_bw,
                child.halign,
                available_width,
                child.width
            )

            table.insert(positioned_children_data, {
                x = child.offset_x + child_x,
                y = child.offset_y + top_side_acc_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            top_side_acc_y = top_side_acc_y + child.height + spacing
        end

        -- bottom-valign elements
        local bottom_side_acc_y = available_height - (padding_bottom + parent_bw)
        for i=#dimensionated_children_data, first_valign_bottom_child_id, -1 do
            local child = dimensionated_children_data[i]
            local child_x = to_internal.align_on_secondary_axis(
                padding_left + parent_bw,
                padding_right + parent_bw,
                child.halign,
                available_width,
                child.width
            )

            bottom_side_acc_y = bottom_side_acc_y - child.height

            table.insert(positioned_children_data, {
                x = child.offset_x + child_x,
                y = child.offset_y + bottom_side_acc_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            bottom_side_acc_y = bottom_side_acc_y - spacing
        end
    else -- position_type == to_internal.POSITION_START
        local top_side_acc_y = padding_top + parent_bw
        for i=1, #dimensionated_children_data do
            local child = dimensionated_children_data[i]
            local child_x = to_internal.align_on_secondary_axis(
                padding_left + parent_bw,
                padding_right + parent_bw,
                child.halign,
                available_width,
                child.width
            )

            table.insert(positioned_children_data, {
                x = child.offset_x + child_x,
                y = child.offset_y + top_side_acc_y,
                width = child.width,
                height = child.height,
                element = child.element,
            })

            top_side_acc_y = top_side_acc_y + child.height + spacing
        end
    end

    return positioned_children_data
end

local function vertical_geometrize_children(vertical, avail_w, avail_h)

    -- NOTE: this will return nil if this branch has no shadow, no bg,
    -- and no sub-children
    if vertical.bg == nil and vertical.shadow == nil and #vertical == 0 then return nil end

    return vertical_position_children(
        vertical_dimensionate_children(vertical, avail_w, avail_h)
    )
end

local function new(args)
    if args == nil then args = {} end

    local defaults = {

        -- part of the interface to be a <terra.oak.elements.branch>
        oak_geometrize_children = vertical_geometrize_children,
        oak_calculate_minimum_dimensions = vertical_calculate_minimum_dimensions,

        -- only horizontal and vertical branches can have spacing
        set_spacing = toeb_internal.set_spacing,
    }

    return tt_table.crush(toeb_branch.new(), defaults, args)
end

return {
    new = new,

    dimensionate_children = vertical_dimensionate_children,
    position_children = vertical_position_children,

    oak_geometrize_children = vertical_geometrize_children,
    oak_calculate_minimum_dimensions = vertical_calculate_minimum_dimensions,
}

