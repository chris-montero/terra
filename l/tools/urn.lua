
-- Parser Combinator Library in lua
-- (C) Chris Montero 2024

local PARSE_SUCCESS = 1
local PARSE_FAILURE = 2
local PARSE_FAILURE_EOF = 3

local function _split(input)
    local spl_input = {}
    for i=1, string.len(input) do
        spl_input[i] = string.sub(input, i, i)
    end
    return spl_input
end

local function _map(arr, fun)
    local mapped = {}
    for _, v in ipairs(arr) do
        table.insert(mapped, fun(v))
    end
    return mapped
end

-- rows are line numbers,
-- columns are the character number on the given row
local function position(row, column)
    return {
        row = row,
        column = column
    }
end

local function success(offset, pos1, pos2)
    return {
        parse_type = PARSE_SUCCESS,
        offset = offset,
        position_start = pos1,
        position_end = pos2,
    }
end

local function failure(offset, pos, chr)
    return {
        parse_type = PARSE_FAILURE,
        offset = offset,
        position = pos,
        char = chr,
    }
end

local function failure_eof(offset, pos)
    return {
        parse_type = PARSE_FAILURE_EOF,
        offset = offset,
        position = pos
    }
end

-- local function map(fun, parsed)
--     parsed.value = fun(parsed.value)
--     return parsed
-- end

local function char(turner, chr)
    return function()
        return function(offset, pos, spl_input)

            local str_chr = spl_input[offset]
            local end_row = pos.row
            local end_col = pos.column
            local end_offset = offset + 1

            if str_chr == chr then
                if str_chr == "\n" then
                    end_row = end_row + 1
                    end_col = 1
                else
                    end_col = end_col + 1
                end

                local succ = success(end_offset, pos, position(end_row, end_col))
                return succ, turner(succ, str_chr)

            else
                local ret = str_chr

                if ret == nil then
                    local fail_eof = failure_eof(offset, position(end_row, end_col))
                    -- we tried to index into the input where there's no char,
                    -- so we treat it as `EOF`
                    return fail_eof, turner(fail_eof, nil)
                end
                local fail = failure(offset, position(end_row, end_col), ret)
                return fail, turner(fail, ret)
            end
        end
    end
end

local function cond(turner, predicate)
    return function()
        return function(offset, pos, spl_input)

            local chr = spl_input[offset]
            local end_row = pos.row
            local end_column = pos.column
            local end_offset = offset + 1

            if chr == nil then
                local fail_eof = failure_eof(offset, position(end_row, end_column))
                return fail_eof, turner(fail_eof, nil)
            end

            if predicate(chr) == true then
                if chr == "\n" then
                    end_row = end_row + 1
                    end_column = 1
                else
                    end_column = end_column + 1
                end

                local succ = success(end_offset, pos, position(end_row, end_column))
                return succ, turner(succ, chr)
            end

            local fail = failure(offset, position(end_row, end_column), chr)
            return fail, turner(fail, chr)
        end
    end
end

local function sequence(turner, parser_constructors)

    return function()
        return function(offset, pos, spl_input)

            local end_row = pos.row
            local end_col = pos.column
            local end_offset = offset

            if #parser_constructors == 0 then
                local succ = success(offset, pos, pos)
                return succ, turner(succ, {})
            end

            local acc = {}

            for _, constructor in ipairs(parser_constructors) do
                local parser = constructor()
                local parsed_data, value = parser(end_offset, position(end_row, end_col), spl_input)

                if parsed_data.parse_type ~= PARSE_SUCCESS then
                    return parsed_data, turner(parsed_data, value)
                end

                if value ~= nil then
                    table.insert(acc, value)
                end

                end_row = parsed_data.position_end.row
                end_col = parsed_data.position_end.column
                end_offset = parsed_data.offset
            end

            local succ_data = success(end_offset, pos, position(end_row, end_col))
            return succ_data, turner(succ_data, acc)
        end
    end
end

local function keyword(turner, kw)
    local function chr_turn(_, c) return c end
    return sequence(turner, _map(_split(kw), function(c) return char(chr_turn, c) end))
end

local function one_or_more(turner, parser_constructor, separator_parser_constructor)
    return function()
        return function(offset, pos, spl_input)
            local parser = parser_constructor()
            local parsed_data, value = parser(offset, pos, spl_input)

            local acc = {}

            if parsed_data.parse_type ~= PARSE_SUCCESS then
                return parsed_data, turner(parsed_data, value)
            else
                if value ~= nil then
                    table.insert(acc, value)
                end
            end

            local end_row = parsed_data.position_end.row
            local end_column = parsed_data.position_end.column
            local end_offset = parsed_data.offset

            if separator_parser_constructor ~= nil then

                local sep_parser = separator_parser_constructor()

                while parsed_data.parse_type == PARSE_SUCCESS do

                    local parsed_sep_data, parsed_sep_value = sep_parser(
                        end_offset,
                        position(end_row, end_column),
                        spl_input
                    )
                    -- if we can't parse a separator, we just return the parsed 
                    -- values we've accumulated so far
                    if parsed_sep_data.parse_type ~= PARSE_SUCCESS then
                        local succ = success(end_offset, pos, position(end_row, end_column))
                        return succ, turner(succ, acc)
                    end

                    local sep_end_row = parsed_sep_data.position_end.row
                    local sep_end_column = parsed_sep_data.position_end.column
                    local sep_end_offset = parsed_sep_data.offset

                    if parsed_sep_value ~= nil then
                        table.insert(acc, parsed_sep_value)
                    end

                    parsed_data, value = parser(
                        sep_end_offset,
                        position(sep_end_row, sep_end_column),
                        spl_input
                    )

                    -- we already parsed a separator so we MUST find a pattern,
                    -- or we fail
                    if parsed_data.parse_type ~= PARSE_SUCCESS then
                        return parsed_data, turner(parsed_data, value)
                    end

                    end_row = parsed_data.position_end.row
                    end_column = parsed_data.position_end.column
                    end_offset = parsed_data.offset

                    if value ~= nil then
                        table.insert(acc, value)
                    end

                end

            else

                while parsed_data.parse_type == PARSE_SUCCESS do

                    parsed_data, value = parser(end_offset, position(end_row, end_column), spl_input)

                    -- we already parsed one, so if we fail here, just return
                    -- what we've already accumulated
                    if parsed_data.parse_type ~= PARSE_SUCCESS then
                        local succ_data = success(end_offset, pos, position(end_row, end_column))
                        return succ_data, turner(succ_data, acc)
                    end

                    end_row = parsed_data.position_end.row
                    end_column = parsed_data.position_end.column
                    end_offset = parsed_data.offset

                    if value ~= nil then
                        table.insert(acc, value)
                    end

                end


            end
        end
    end
end

local function zero_or_more(turner, parser_constructor, separator_parser)
    return function()
        return function(offset, pos, spl_input)
            local parser = one_or_more(turner, parser_constructor, separator_parser)()
            local parsed_data, value = parser(offset, pos, spl_input)

            if parsed_data.parse_type ~= PARSE_SUCCESS then
                -- if we couldn't parse anything, both position_start and
                -- position_end are the same
                local succ = success(offset, pos, pos)
                return succ, turner(succ, {})
            end

            -- no need to apply the turner function. it already gets applied
            -- above, when we call "one_or_more"
            return parsed_data, value
        end
    end
end

local function one_of(turner, parser_constructors)
    return function()
        return function(offset, pos, spl_input)

            for _, constructor in ipairs(parser_constructors) do

                local parser = constructor()
                local parsed_data, value = parser(offset, pos, spl_input)

                if parsed_data.parse_type == PARSE_SUCCESS then
                    local end_offset = parsed_data.offset
                    local succ = success(end_offset, parsed_data.position_start, parsed_data.position_end)
                    return succ, turner(succ, value)
                end
            end

            local fail_chr = spl_input[offset]
            local fail
            if fail_chr == nil then
                -- if none of the parsers succeeded, and the first character we
                -- get is nil, that should only mean we've reached the end of file
                fail = failure_eof(offset, pos)
            else
                fail = failure(offset, pos, fail_chr)
            end

            return fail, turner(fail, fail_chr)

        end
    end
end


local function maybe(turner, parser_constructor)
    return function()
        return function(offset, pos, spl_input)
            local parser = parser_constructor()
            local parsed_data, parsed_value = parser(offset, pos, spl_input)

            local succ
            if parsed_data.parse_type ~= PARSE_SUCCESS then
                -- we use same position for start and end, and same offset, so
                -- other parsers can pick up where this failed
                succ = success(offset, pos, pos)
                parsed_value = nil
            else
                succ = success(
                    parsed_data.offset,
                    parsed_data.position_start,
                    parsed_data.position_end
                )

            end
            return succ, turner(succ, parsed_value)
        end
    end
end

local function run(parser_constructor, input)
    local parser = parser_constructor()
    local starting_position = position(1, 1) -- row 1, column 1
    local parsed_data, parsed_value = parser(1, starting_position, _split(input))
    return parsed_data, parsed_value
end


return {

    -- map = map,

    PARSE_SUCCESS = PARSE_SUCCESS,
    PARSE_FAILURE = PARSE_FAILURE,
    PARSE_FAILURE_EOF = PARSE_FAILURE_EOF,

    char = char,
    cond = cond,
    keyword = keyword,
    maybe = maybe,
    sequence = sequence,
    one_or_more = one_or_more,
    zero_or_more = zero_or_more,
    -- any_of = any_of,
    one_of = one_of,

    run = run,
}
