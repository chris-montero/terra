
local EPSILON = 0.00001

local function exponential_ease(x, a)

    local min_a = 0 + EPSILON
    local max_a = 1 - EPSILON
    a = math.max(min_a, math.min(a, max_a))

    if a < 0.5 then
        a = 2 * a
        return math.pow(x, a)
    else
        a = 2 * (a - 0.5)
        return math.pow(x, 1/(1-a))
    end

end

return {
    exponential_ease = exponential_ease,
}
