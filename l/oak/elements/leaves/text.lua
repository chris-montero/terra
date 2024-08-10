
local lgi = require("lgi")

local tt_color = require("terra.tools.color")
local tt_table = require("terra.tools.table")

local to_source = require("terra.oak.source")
local to_size = require("terra.oak.size")
local toel_leaf = require("terra.oak.elements.leaves.leaf")

-- local build_typeface_description = function(family, weight, size)
--     family = family or "Sans"
--     weight = weight or "Regular"
--     size = size or 14
--     return
--         family .. " " ..
--         weight .. " " ..
--         tostring(size)
-- end

-- local function text_set_geometry(self, x, y, width, height)
--
--     -- if not lgi.Pango.FontDescription.equal(self._font_description, self._text_layout:get_font_description()) then
--     --     self._text_layout:set_font_description(self._font_description)
--     -- end
--
--     self.oak_geometry.x = x
--     self.oak_geometry.y = y
--     self.oak_geometry.width = width
--     self.oak_geometry.height = height
--     -- self._text_layout:set_width(lgi.Pango.units_from_double(width))
--     -- self._text_layout:set_height(lgi.Pango.units_from_double(height))
-- end

local function oak_draw(self, cr, avail_w, avail_h)

    local text_layout = self._text_layout

    if not lgi.Pango.FontDescription.equal(self._font_description, text_layout:get_font_description()) then
        text_layout:set_font_description(self._font_description)
    end

    -- local screen_dpi = self.layout_data.screen.dpi
    local screen_dpi = 96 -- TODO: do this properly
    if screen_dpi ~= text_layout.context:get_resolution() then
        text_layout.context:set_resolution(screen_dpi)
    end

    -- if self.id ~= nil then
    --     cr:set_source(to_source.to_cairo_source(tt_color.rgba(0, 1, 0, 0.3)))
    --     cr:rectangle(0, 0, log.width, log.height)
    --     cr:fill()
    -- end

    -- if not to_size.is_shrink(self.width) then
    --     self._text_layout:set_width(lgi.Pango.units_from_double(avail_w))
    -- end
    -- if not to_size.is_shrink(self.height) then
    --     self._text_layout:set_height(lgi.Pango.units_from_double(avail_h))
    -- end

    if self.bg ~= nil then
        local halign = text_layout:get_alignment()
        local _, layout_dimensions = text_layout:get_pixel_extents()
        if layout_dimensions.width ~= 0 and layout_dimensions.height ~= 0 then
            local spacing = lgi.Pango.units_to_double(text_layout:get_spacing())
            local line_y = 0
            cr:save()
            cr:set_source(to_source.to_cairo_source(self.bg))
            if halign == "CENTER" then
                for _, line in ipairs(text_layout:get_lines()) do
                    local _, line_dimensions = line:get_pixel_extents()
                    local line_x = (avail_w / 2) - (line_dimensions.width / 2)
                    cr:rectangle(line_x, line_y, line_dimensions.width, line_dimensions.height)
                    line_y = line_y + line_dimensions.height + spacing
                end
            elseif halign == "RIGHT" then
                for _, line in ipairs(text_layout:get_lines()) do
                    local _, line_dimensions = line:get_pixel_extents()
                    local line_x = avail_w - line_dimensions.width
                    cr:rectangle(line_x, line_y, line_dimensions.width, line_dimensions.height)
                    line_y = line_y + line_dimensions.height + spacing
                end
            else
                for _, line in ipairs(text_layout:get_lines()) do
                    local _, line_dimensions = line:get_pixel_extents()
                    -- print("line_dimensions.x, line_dimensions.y, line_dimensions.width, line_dimensions.height")
                    -- print(line_dimensions.x, line_dimensions.y, line_dimensions.width, line_dimensions.height)
                    cr:rectangle(0, line_y, line_dimensions.width, line_dimensions.height)
                    line_y = line_y + line_dimensions.height + spacing
                end
            end
            cr:fill()
            cr:restore()
        end
    -- else
    --     cr:set_source(to_source.to_cairo_source(tt_color.rgba(0, 1, 0, 0.3)))
    --     cr:rectangle(0, 0, avail_w, avail_h)
    --     cr:fill()
    end

    cr:set_source(to_source.to_cairo_source(self.fg))
    -- cr:update_layout(self._text_layout)
    cr:show_layout(self._text_layout)
end

local function text_calculate_minimum_dimensions(self, constraint_w, constraint_h)

    local text_layout = self._text_layout

    if not lgi.Pango.FontDescription.equal(self._font_description, text_layout:get_font_description()) then
        text_layout:set_font_description(self._font_description)
    end

    local w, h = -1, -1

    if type(self.width) == "number" then
        w = self.width
    elseif to_size.is_fill(self.width) then
        w = constraint_w
    end

    if type(self.height) == "number" then
        h = self.height
    elseif to_size.is_fill(self.height) then
        h = constraint_h
    end

    -- local pango_size = lgi.Pango.AttrSize.new(self.size * lgi.Pango.SCALE)
    -- lgi.Pango.AttrList.change(self.pango_attrs, pango_size)

    -- set the text dpi in case the screen dpi changed (for example, if the
    -- layout this text elements is drawn by was moved to a different screen)
    -- local screen_dpi = self.layout_data.screen.dpi
    -- if screen_dpi ~= text_layout.context:get_resolution() then
    --     text_layout.context:set_resolution(screen_dpi)
    -- end

    local final_w, final_h
    -- set the width and height temporarily to get our answer, then set the old
    -- values back.
    -- local old_w, old_h = self._text_layout:get_width(), self._text_layout:get_height()
    self._text_layout:set_width(lgi.Pango.units_from_double(w))
    self._text_layout:set_height(lgi.Pango.units_from_double(h))
    local _, logical = self._text_layout:get_pixel_extents()
    final_w, final_h = logical.width, logical.height
    -- we add + 4 to the end text because some fonts get cut off at the end.
    -- They either get wrapped, or clipped, so this should alleviate that problem
    if final_w ~= 0 then final_w = final_w + 4 end

    -- self._text_layout:set_width(old_w)
    -- self._text_layout:set_height(old_h)

    return final_w, final_h
end

local function set_text_halign(txt, halign)
    txt.text_halign = halign
    txt._text_layout:set_alignment("RIGHT")
end

local function set_text(text_el, txt)
    text_el.text = txt
    text_el._text_layout:set_text(txt)
    -- if to_size.is_shrink(text_el.width) then
    --     text_el._text_layout:set_width(lgi.Pango.units_from_double(-1))
    -- end
end

local function set_size(text_el, s)
    text_el.size = s
    lgi.Pango.FontDescription.set_size(text_el._font_description, s * lgi.Pango.SCALE)
end

local function set_family(text_el, f)
    text_el.family = f
    lgi.Pango.FontDescription.set_family(text_el._font_description, f)
end

local function set_weight(text_el, w)
    text_el.weight = w
    lgi.Pango.FontDescription.set_weight(text_el._font_description, w)
end

local function new(args)

    local defaults = {

        bg = nil,
        fg = tt_color.rgb_from_string("#000000"),
        letter_spacing = 0,
        line_spacing = 0, -- TODO
        -- text_halign -- TODO
        text = "",
        family = "Sans",
        weight = "Regular",
        size = 12,

        caret_position = 0,
        text_halign = "LEFT",

        oak_draw = oak_draw,
        oak_calculate_minimum_dimensions = text_calculate_minimum_dimensions,

        set_text = set_text,
        set_text_halign = set_text_halign,
        set_size = set_size,
        set_family = set_family,
        set_weight = set_weight,
    }

    local text_elem = tt_table.crush(toel_leaf.new(), defaults, args)

    local built_typeface_description =
        text_elem.family .. " " ..
        text_elem.weight .. ' ' ..
        text_elem.size

    local desc = lgi.Pango.FontDescription.from_string(built_typeface_description)

    local open_type_features = {}

    local ctx = lgi.PangoCairo.font_map_get_default():create_context()
    local text_layout = lgi.Pango.Layout.new(ctx)
    text_layout.text = text_elem.text
    text_layout:set_font_description(desc)
    text_layout:set_wrap("WORD_CHAR")

    local pango_attrs = lgi.Pango.AttrList.new()

    local pango_letter_spacing = lgi.Pango.attr_letter_spacing_new(
        lgi.Pango.units_from_double(text_elem.letter_spacing)
    )

    lgi.Pango.AttrList.insert(pango_attrs, pango_letter_spacing)
    text_layout:set_attributes(pango_attrs)
    text_layout:set_ellipsize("END")

    if args.text_align ~= nil then
        text_layout:set_alignment(args.text_align)
    end

    text_elem._text_layout = text_layout
    text_elem._pango_attrs = pango_attrs
    text_elem._font_description = desc

    return text_elem
end

local function get_caret_geometry(text_el, graphene_index)

    -- NOTE: I don't get it. why the hell do you have to supply two numbers to 
    -- this function? one to say "Here's where my caret (which you store in 
    -- memory) is in the layout". Then, another number to mean "from where I 
    -- just said the caret is, move this much to the left or right." Why can't 
    -- I just give you the number where my caret is, and if I want to "move to 
    -- the right by 1", I just add or subtract `1` to the first number before 
    -- giving it to you?

    -- Glossary:
    -- graphene: a "text bit" which normally looks like a single character but 
    -- that is actually comprised of multiple unicode characters. This is how
    -- "cursed text" generators work

    local pango_caret_pos
    if graphene_index <= 0 then
        -- we have to do this because apparently trying to "move_cursor_visually" to
        -- position '0' will put the caret AFTER THE FIRST LETTER.
        pango_caret_pos = lgi.Pango.Layout.get_caret_pos(text_el._text_layout, 0)

    elseif graphene_index >= text_el._text_layout:get_character_count() then
        pango_caret_pos = lgi.Pango.Layout.get_caret_pos(
            text_el._text_layout,
            text_el._text_layout:get_character_count()
        )
    else
        pango_caret_pos = lgi.Pango.Layout.get_caret_pos(text_el._text_layout, graphene_index)
    end

    -- local a ,_ = lgi.Pango.Layout.move_cursor_visually(
    --     text_el._text_layout,
    --     true, -- move "strong" cursor. (whatever that means to pango. why do you need 2 cursors?)
    --     graphene_index - 1, -- "I am 'here' in the layout" (apparently saying 
    --                         -- you're at index '1' puts your caret after the
    --                         -- SECOND letter. stupid)
    --     0, -- "from 'here', move this many graphenes to the right or left". see NOTE
    --     0 -- this has to do with things like graphenes formed from a bunch of
    --       -- different unicode characters. Setting this to 0 normally works, but
    --       -- will probably break when encountering graphenes formed of multiple
    --       -- unicode characters, but we'll fix that later lol
    -- )

    -- use a rect for caret position, because carets can be sloped if we have
    -- an italic layout. The width of this rect would tell you how much the
    -- caret is sloped
    return {
        x = pango_caret_pos.x / lgi.Pango.SCALE,
        y = pango_caret_pos.y / lgi.Pango.SCALE,
        width = pango_caret_pos.width / lgi.Pango.SCALE,
        height = pango_caret_pos.height / lgi.Pango.SCALE,
    }
end

return {
    new = new,

    get_caret_geometry = get_caret_geometry,
    set_text = set_text,
    set_text_halign = set_text_halign,
    set_size = set_size,
    set_family = set_family,
    set_weight = set_weight,

    oak_draw = oak_draw,
    oak_calculate_minimum_dimensions = text_calculate_minimum_dimensions,
}

