
local tstation = require("tstation")

-- create a new terra object. This object has the potential to have events 
-- emitted on its station.
local function new()
    return {
        station = tstation.new()
    }
end

return {
    new = new,
}
