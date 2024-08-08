
local function circle(cr, x, y, radius)
    cr:arc(x, y, radius, 0, 2*math.pi)
    cr:close_path()
end

local function rounded_rectangle(cr, width, height, radius)
    local constrained_rad = math.min(math.floor(math.min(width, height)/2), radius)

    local quarter_pi = math.pi/2
    local h_point_a = constrained_rad
    local h_point_b = width - constrained_rad
    local v_point_a = constrained_rad
    local v_point_b = height - constrained_rad

    cr:move_to(h_point_a, 0)
    cr:line_to(h_point_b, 0)
    cr:arc(h_point_b, v_point_a, constrained_rad, -quarter_pi, 0)
    cr:line_to(width, v_point_b)
    cr:arc(h_point_b, v_point_b, constrained_rad, 0, quarter_pi)
    cr:line_to(h_point_a, height)
    cr:arc(h_point_a, v_point_b, constrained_rad, quarter_pi, math.pi)
    cr:line_to(0, v_point_a)
    cr:arc(h_point_a, v_point_a, constrained_rad, math.pi, math.pi + quarter_pi)
    cr:close_path()

end

local function rounded_rectangle_each(cr, width, height, tl, tr, br, bl)

    local max_rad = math.floor(math.min(width, height) / 2)
    tl = math.min(tl, max_rad)
    tr = math.min(tr, max_rad)
    br = math.min(br, max_rad)
    bl = math.min(bl, max_rad)

    local quarter_pi = math.pi/2

    cr:move_to(tl, 0)
    cr:line_to(width - tr, 0)
    if tr > 0 then cr:arc(width - tr, tr, tr, -quarter_pi, 0) end
    cr:line_to(width, height - br)
    if br > 0 then cr:arc(width - br, height - br, br, 0, quarter_pi) end
    cr:line_to(bl, height)
    if bl > 0 then cr:arc(bl, height - bl, bl, quarter_pi, math.pi) end
    cr:line_to(0, tl)
    if tl > 0 then cr:arc(tl, tl, tl, math.pi, math.pi + quarter_pi) end
    cr:close_path()

end

return {
    circle = circle,
    rounded_rectangle = rounded_rectangle,
    rounded_rectangle_each = rounded_rectangle_each,
}
