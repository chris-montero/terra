
local to_align = require("terra.oak.align")

local function align_on_secondary_axis(padding_start, padding_end, align_, context_size, element_size)
    if align_ == to_align.BOTTOM or align_ == to_align.RIGHT then
        return context_size - (element_size + padding_end)
    elseif align_ == to_align.CENTER then
        return (context_size / 2) - (element_size / 2)
    else
        return padding_start
    end
end

return {
    align_on_secondary_axis = align_on_secondary_axis,
}
