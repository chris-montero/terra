
local tt_urn = require("terra.tools.urn")

local function id(_, a) return a end
local function di(_, _) return nil end

local function _extract1(pd, v)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return v[1]
    end
end
local function _split(s)
    local spl = {}
    for i=1, string.len(s) do
        table.insert(spl, string.sub(s, i, i))
    end
    return spl
end

local function _is_one_nine(c)
    local b = string.byte(c)
    if b >= 0x0031 and b <= 0x0039 then -- ascii 1 - 9
        return true
    end
    return false
end

local function _is_digit(c)
    local b = string.byte(c)
    if b >= 0x0030 and b <= 0x0039 then -- ascii 0 - 9
        return true
    end
    return false
end

local function _is_jstring_char(chr)
    local b = string.byte(chr)

    if b == 34 then return false end -- 34 ascii is `"`
    if b == 92 then return false end -- 92 ascii is `\`

    if b >= 32 and b <= 127 then
        return true
    end

    return false
end

local function _stitch_int(pd, first_and_rest)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        local fin = {first_and_rest[1]}
        for _, dig in ipairs(first_and_rest[2]) do
            table.insert(fin, dig)
        end
        return fin
    end
end

local SIGN_PLUS = 1
local SIGN_MINUS = 2
local function _make_plus()
    return SIGN_PLUS
end
local function _make_minus()
    return SIGN_MINUS
end

local function _determine_sign(pd, _)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return SIGN_PLUS
    else
        return SIGN_MINUS
    end
end
local function _form_int(pd, d)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        if d[1] == SIGN_PLUS then
            return tonumber(table.concat(d[2]))
        else
            return -tonumber(table.concat(d[2]))
        end
    end
end

local NUM_PART_FRACTION = 1
local NUM_PART_EXPONENT = 2
local function _make_fraction(_, f)
    return {
        num_part_type = NUM_PART_FRACTION,
        value = f
    }
end
local function _make_exponent(_, e)
    return {
        num_part_type = NUM_PART_EXPONENT,
        value = e
    }
end
local function _to_exponent(pd, v)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return {
            sign = v[1],
            value = v[2],
        }
    end
end


local VALUE_NULL = 1
local VALUE_BOOL = 2
local VALUE_STRING = 3
local VALUE_NUMBER = 4

local function make_null() return { value_type = VALUE_NULL } end
local function make_true() return { value_type = VALUE_BOOL, value = true } end
local function make_false() return { value_type = VALUE_BOOL, value = false } end
local function make_string(str) return { value_type = VALUE_STRING, value = str } end
local function make_number(int, frac, exp)
    return {
        value_type = VALUE_NUMBER,
        integer = int,
        fraction = frac,
        exponent = exp
    }
end

local function to_null(pd, _)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return make_null()
    end
end
local function to_true(pd, _)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return make_true()
    end
end
local function to_false(pd, _)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return make_false()
    end
end
local function to_string(pd, v)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return make_string(table.concat(v[1]))
    end
end
local function to_number(pd, number_data)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return make_number(
            number_data[1],
            number_data[2].value,
            number_data[3].value
        )
    end
    return {}
end
local function to_array(pd, a)
    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        return a[1]
    end
    return {}
end
local function to_object(pd, maybe_members)

    if pd.parse_type == tt_urn.PARSE_SUCCESS then
        local members = maybe_members[1]
        if members == nil then
            return {}
        end
        local obj = {}
        for _, member in ipairs(members) do
            local str = member[1].value
            local val = member[2]
            obj[str] = val
        end
        return obj
    end

end

local _whitespace = tt_urn.one_of(id, {
    tt_urn.char(id, ' '),
    tt_urn.char(id, '\n'),
    tt_urn.char(id, '\r'),
    tt_urn.char(id, '\t'),
})

local _json_sign = tt_urn.maybe(function(pd, v)
        if pd.parse_type == tt_urn.PARSE_SUCCESS then
            if v == nil then
                return _make_plus()
            else
                return v
            end
        end
    end,
    tt_urn.one_of(id, {
        tt_urn.char(_make_plus, "+"),
        tt_urn.char(_make_minus, "-")
    })
)

local _json_integer = tt_urn.sequence(_form_int, {
    tt_urn.maybe(_determine_sign, tt_urn.char(id, '-')),
    tt_urn.one_of(id, {
        tt_urn.sequence(_stitch_int, {
            tt_urn.cond(id, _is_one_nine),
            tt_urn.one_or_more(id, tt_urn.cond(id, _is_digit))
        }),
        tt_urn.cond(id, _is_digit),
    })
})

local _json_fraction = tt_urn.sequence(_extract1, {
    tt_urn.char(di, '.'),
    tt_urn.one_or_more(id, tt_urn.cond(id, _is_digit))
})

local _json_exponent = tt_urn.sequence(_to_exponent, {
    tt_urn.one_of(di, {
        tt_urn.char(di, 'e'),
        tt_urn.char(di, 'E')
    }),
    _json_sign,
    tt_urn.zero_or_more(id, tt_urn.cond(id, _is_digit))
})



local json_value
local json_array
local json_object

local json_null = tt_urn.keyword(to_null, "null")
local json_bool = tt_urn.one_of(id, {
    tt_urn.keyword(to_true, "true"),
    tt_urn.keyword(to_false, "false")
})
local json_string = tt_urn.sequence(to_string, {
    tt_urn.char(di, '"'),
    tt_urn.zero_or_more(id, tt_urn.cond(id, _is_jstring_char)),
    tt_urn.char(di, '"')
})

local json_number = tt_urn.sequence(to_number, {
    _json_integer,
    tt_urn.maybe(_make_fraction, _json_fraction),
    tt_urn.maybe(_make_exponent, _json_exponent)
})

json_array = function()
    return tt_urn.sequence(to_array, {
        tt_urn.char(di, '['),
        tt_urn.zero_or_more(di, _whitespace),
        tt_urn.zero_or_more(id, json_value,
            tt_urn.sequence(di, {
                tt_urn.zero_or_more(di, _whitespace),
                tt_urn.char(di, ','),
                tt_urn.zero_or_more(di, _whitespace),
            })
        ),
        tt_urn.zero_or_more(di, _whitespace),
        tt_urn.char(di, ']')
    })()
end

local _json_member = function()
    return tt_urn.sequence(id, {
        tt_urn.zero_or_more(di, _whitespace),
        json_string,
        tt_urn.zero_or_more(di, _whitespace),
        tt_urn.char(di, ':'),
        tt_urn.zero_or_more(di, _whitespace),
        json_value,
        tt_urn.zero_or_more(di, _whitespace),
    })()
end
json_object = function()
    return tt_urn.sequence(to_object, {
        tt_urn.char(di, '{'),
        tt_urn.zero_or_more(id, _json_member, tt_urn.char(di, ',')),
        tt_urn.char(di, '}')
    })()
end

json_value = function()
    return tt_urn.one_of(id, {
        json_null,
        json_bool,
        json_string,
        json_number,
        json_array,
        json_object
    })()
end









describe("parses ascii json", function()

    it( "parses json null values", function()
        local test_pd, test_val = tt_urn.run(json_value, "null")
        assert.is_same(test_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 5,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 5,
            }
        })
        assert.is_same(test_val, make_null())
    end)

    it("parses json booleans", function()
        local test_true_pd, test_true_val = tt_urn.run(json_value, "true")
        assert.is_same(test_true_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 5,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 5,
            }
        })
        assert.is_same(test_true_val, make_true())

        local test_false_pd, test_false_val = tt_urn.run(json_value, "false")
        assert.is_same(test_false_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 6,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 6,
            }
        })
        assert.is_same(test_false_val, make_false())
    end)

    it("parses json strings", function()
        local test_pd, test_val = tt_urn.run(json_value, '"this is a string."')
        assert.is_same(test_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 20,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 20,
            }
        })
        assert.is_same(test_val, make_string('this is a string.'))
    end)

    it("parses json numbers", function()
        local test_number_int_pd, test_number_int_val = tt_urn.run(json_value, '13')
        assert.is_same(test_number_int_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 3,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 3,
            }
        })
        assert.is_same(test_number_int_val, {
            value_type = VALUE_NUMBER,
            integer = 13
        })

        local test_number_frac_pd, test_number_frac_val = tt_urn.run(json_value, '69.420')
        assert.is_same(test_number_frac_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 7,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 7,
            }
        })
        assert.is_same(test_number_frac_val, {
            value_type = VALUE_NUMBER,
            integer = 69,
            fraction = _split("420")
        })

        local test_number_exp_pd, test_number_exp_val = tt_urn.run(json_value, '69.420e-21')
        assert.is_same(test_number_exp_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 11,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 11
            }
        })

        assert.is_same(test_number_exp_val, {
            value_type = VALUE_NUMBER,
            integer = 69,
            fraction = _split("420"),
            exponent = {
                sign = SIGN_MINUS,
                value = _split("21"),
            }
        })
    end)

    it("parses empty json arrays", function()
        local test_pd, test_val = tt_urn.run(json_value, '[]')
        assert.is_same(test_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 3,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 3
            }
        })
        assert.is_same(test_val, {})
    end)

    it("parses json arrays containing non-list values", function()
        local test_pd, test_val = tt_urn.run(json_value, '[ 122, "a szegeny ember" ]')
        assert.is_same(test_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 27,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 27
            }
        })
        assert.is_same(test_val, {
            {
                value_type = VALUE_NUMBER,
                integer = 122,
            },
            {
                value_type = VALUE_STRING,
                value = "a szegeny ember",
            }
        })
    end)

    it("parses nested json arrays", function()
        local test_pd, test_val = tt_urn.run(json_value, '[[[]]]')
        assert.is_same(test_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 7,
            position_start = {
                row = 1,
                column = 1,
            },
            position_end = {
                row = 1,
                column = 7,
            }
        })
        assert.is_same(test_val, {{{}}})
    end)

    it("parses empty json objects", function()
        local test_empty_obj_pd, test_empty_obj_val = tt_urn.run(json_value, "{}")
        assert.is_same(test_empty_obj_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 3,
            position_start = {
                row = 1,
                column = 1
            },
            position_end = {
                row = 1,
                column = 3
            }
        })
        assert.is_same(test_empty_obj_val, {})
    end)

    it("parses json objects", function()
        local test_obj_pd, test_obj_val = tt_urn.run(json_value, '{ "hello" : 154.33 }')
        assert.is_same(test_obj_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 21,
            position_start = {
                row = 1,
                column = 1
            },
            position_end = {
                row = 1,
                column = 21
            }
        })
        assert.is_same(test_obj_val, {
            hello = {
                value_type = VALUE_NUMBER,
                fraction = { '3', '3' },
                integer = 154,
            }
        })

    end)

    it("parses recursive json objects", function()
        local test_obj_pd, test_obj_val = tt_urn.run(json_value, '{ "stinky" : { "binky" : true } }')
        assert.is_same(test_obj_pd, {
            parse_type = tt_urn.PARSE_SUCCESS,
            offset = 34,
            position_start = {
                row = 1,
                column = 1
            },
            position_end = {
                row = 1,
                column = 34
            }
        })
        assert.is_same(test_obj_val, {
            stinky = {
                binky = {
                    value_type = VALUE_BOOL,
                    value = true,
                }
            }
        })

    end)

end)


