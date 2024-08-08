
local lib = {
    ANY = 0, -- literal keycode to signify "any key"

    MOD_NONE = 0,
    MOD_SHIFT = 1, -- 1 << 0
    MOD_LOCK = 2, -- 1 << 1
    MOD_CONTROL = 4, -- 1 << 2
    MOD_1 = 8, -- 1 << 3
    MOD_2 = 16, -- 1 << 4
    MOD_3 = 32, -- 1 << 5
    MOD_4 = 64, -- 1 << 6
    MOD_5 = 128, -- 1 << 7
    MOD_ANY = 32768 -- 1 << 15
}

return lib

