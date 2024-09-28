
local tt_urn = require("terra.tools.urn")

local function id(_, a) return a end
local function di(_, _) return nil end

describe("tools.urn", function()
    it(
        [[\
        parses '0' as a string, keeps it, allows you to turn it into a number, 
        and returns that number after parsing
        ]],
        function()

            local function make_num(parsed_data, parsed_zero)
                if parsed_data.parse_type == tt_urn.PARSE_FAILURE then
                    error("couldn't parse char: ".. tostring(parsed_zero.value))
                end

                return tonumber(parsed_zero)
            end

            local zero_parser = tt_urn.char(make_num, '0')
            local parsed_data, parsed_value = tt_urn.run(zero_parser, "0")

            assert(parsed_data.parse_type == tt_urn.PARSE_SUCCESS)
            assert(parsed_data.position_start.row == 1)
            assert(parsed_data.position_start.column == 1)
            assert(parsed_data.position_end.row == 1)
            assert(parsed_data.position_end.column == 2)
            assert(parsed_value == 0)

        end
    )


    it(
        [[\
        parses a sequence of '1's as a string, allows you to turn it into a
        number, and returns that number after parsing. Additionally, it fails
        when it should, allowing you to parameterize exactly the error type you
        get back, and do whatever you want with it
        ]],
        function()

            local RESULT_SUCCESS = 1

            local RESULT_PROBLEM_EOF = 2
            local RESULT_PROBLEM_UNEXPECTED_CHAR = 3

            local function problem_unexpected_char(offset, position, chr)
                return {
                    result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                    position = position,
                    offset = offset,
                    value = chr
                }
            end

            local function problem_eof(position)
                return {
                    result_type = RESULT_PROBLEM_EOF,
                    position = position,
                }
            end

            local function success(val)
                return {
                    result_type = RESULT_SUCCESS,
                    value = val,
                }
            end

            local function propagate(parsed_data, value)

                if parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return problem_eof(parsed_data.position)
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE then
                    return problem_unexpected_char(
                        parsed_data.offset,
                        parsed_data.position,
                        parsed_data.char
                    )
                else
                    return success(value)
                end

            end

            local function make_num(_, digits)
                return digits
            end

            local one_parser = tt_urn.char(propagate, '1')
            local chomp_ones = tt_urn.sequence(make_num, {
                one_parser,
                one_parser,
                one_parser,
            })

            local success_parse_data, success_val = tt_urn.run(chomp_ones, "111")
            assert.is_same(success_parse_data, {
                parse_type = tt_urn.PARSE_SUCCESS,
                offset = 4,
                position_start = {
                    row = 1,
                    column = 1,
                },
                position_end = {
                    row = 1,
                    column = 4,
                }
            })
            assert.is_same(success_val, {
                success("1"),
                success("1"),
                success("1"),
            })


            local failure_eof_parse_data, failure_eof_val = tt_urn.run(chomp_ones, "11")
            assert.is_same(failure_eof_parse_data, {
                offset = 3,
                parse_type = tt_urn.PARSE_FAILURE_EOF,
                position = {
                    row = 1,
                    column = 3,
                }
            })
            assert.is_same(failure_eof_val, problem_eof({ row = 1, column = 3 }))


            local failure_char_parse_data, failure_char_val = tt_urn.run(chomp_ones, "121")
            assert.is_same(failure_char_parse_data, {
                char = '2',
                offset = 2,
                parse_type = tt_urn.PARSE_FAILURE,
                position = {
                    row = 1,
                    column = 2
                }
            })
            assert.is_same(failure_char_val,
                problem_unexpected_char(2, {row = 1, column = 2}, '2')
            )

        end
    )

    it(
        [[\
        parses one or more '1's as a string, and allows you to turn it into a 
        number, and returns that number after parsing
        ]],
        function()

            local RESULT_SUCCESS = 1
            local RESULT_PROBLEM_EOF = 2
            local RESULT_PROBLEM_UNEXPECTED_CHAR = 3

            local function make_success(val)
                return {
                    result_type = RESULT_SUCCESS,
                    value = val,
                }
            end

            local function make_problem_eof(position)
                return {
                    result_type = RESULT_PROBLEM_EOF,
                    position = position,
                }
            end

            local function make_problem_unexpected_char(position, chr)
                return {
                    result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                    position = position,
                    value = chr,
                }
            end

            local function propagate_char(parsed_data, c)

                if parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE then
                    return make_problem_unexpected_char(parsed_data.position, parsed_data.char)
                else
                    return make_success(c)
                end
            end

            local function make_num(_, val)
                return val
            end

            local one_parser = tt_urn.char(propagate_char, '1')
            local chomp_ones = tt_urn.one_or_more(make_num, one_parser)

            local success_parsed_data, success_val = tt_urn.run(chomp_ones, "1111")
            assert.is_same(success_parsed_data, {
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
            assert.is_same(success_val, {
                make_success("1"),
                make_success("1"),
                make_success("1"),
                make_success("1"),
            })

            local failure_unexpected_char_parsed_data,
                failure_unexpected_char_value = tt_urn.run(chomp_ones, "21")
            assert.is_same(failure_unexpected_char_parsed_data, {
                parse_type = tt_urn.PARSE_FAILURE,
                char = "2",
                offset = 1,
                position = {
                    row = 1,
                    column = 1,
                }
            })
            assert.is_same(failure_unexpected_char_value,
                make_problem_unexpected_char({row = 1, column = 1}, "2")
            )

        end
    )

    it(
        [[\
        parses one or more digits (0 - 9) as a string, allows you to turn it 
        into a number, and returns that number after parsing
        ]],
        function()

            local RESULT_SUCCESS = 1
            local RESULT_PROBLEM_NO_DIGIT_FOUND = 2

            local function make_success_found_digits(digits)
                return {
                    result_type = RESULT_SUCCESS,
                    value = digits,
                }
            end

            local function make_problem_no_digit_found(position, chr)
                return {
                    result_type = RESULT_PROBLEM_NO_DIGIT_FOUND,
                    position = position,
                    value = chr,
                }
            end

            local function prop_char(_, chr)
                return chr
            end

            local process_digits = function(parse_data, val)
                if parse_data.parse_type == tt_urn.PARSE_FAILURE then
                    return make_problem_no_digit_found(parse_data.position, parse_data.char)
                else
                    return make_success_found_digits(val)
                end
            end

            local digit_parser = tt_urn.one_of(prop_char, {
                tt_urn.char(prop_char, '0'),
                tt_urn.char(prop_char, '1'),
                tt_urn.char(prop_char, '2'),
                tt_urn.char(prop_char, '3'),
                tt_urn.char(prop_char, '4'),
                tt_urn.char(prop_char, '5'),
                tt_urn.char(prop_char, '6'),
                tt_urn.char(prop_char, '7'),
                tt_urn.char(prop_char, '8'),
                tt_urn.char(prop_char, '9'),
            })

            local parse_many_digits = tt_urn.one_or_more(process_digits, digit_parser)

            local success_parse_data, success_val = tt_urn.run(parse_many_digits, "3456")
            assert.is_same(success_parse_data, {
                parse_type = tt_urn.PARSE_SUCCESS,
                position_start = {
                    row = 1,
                    column = 1,
                },
                position_end = {
                    row = 1,
                    column = 5,
                },
                offset = 5,
            })
            assert.is_same(success_val, make_success_found_digits({'3', '4', '5', '6'}))

            local failure_no_digits_parse_data,
                failure_val = tt_urn.run(parse_many_digits, "no digits")

            assert.is_same(failure_no_digits_parse_data, {
                parse_type = tt_urn.PARSE_FAILURE,
                char = "n",
                position = {
                    row = 1,
                    column = 1,
                },
                offset = 1,
            })
            assert.is_same(failure_val, make_problem_no_digit_found({row = 1, column = 1}, 'n'))

        end
    )

    it(
        [[\
        parses zero or more 'a's
        ]],
        function()

            local a_parser = tt_urn.char(id, 'a')

            local function letters_to_word(_, letters)
                return table.concat(letters)
            end

            local many_a_parser = tt_urn.zero_or_more(letters_to_word, a_parser)

            local parsed_data, parsed_value = tt_urn.run(many_a_parser, "aaa")
            assert.is_same(parsed_data, {
                parse_type = tt_urn.PARSE_SUCCESS,
                position_start = {
                    row = 1,
                    column = 1,
                },
                position_end = {
                    row = 1,
                    column = 4,
                },
                offset = 4,
            })
            assert(parsed_value == "aaa")

        end
    )


    it(
        [[\
        parses a tuple of the form "( 17, 23 )", discarding what's not needed,
        keeping the digits, allowing you to turn them to numbers, puts them
        in a lua list, and returns it to you
        ]],
        function()

            local RESULT_SUCCESS = 1
            local RESULT_PROBLEM_EOF = 2
            local RESULT_PROBLEM_PARSING_NUMBER = 3
            local RESULT_PROBLEM_UNEXPECTED_CHAR = 4

            local function make_success(value)
                return {
                    result_type = RESULT_SUCCESS,
                    value = value,
                }
            end

            local function make_problem_eof(position)
                return {
                    result_type = RESULT_PROBLEM_EOF,
                    position = position,
                }
            end

            local function make_problem_make_num(position)
                return {
                    result_type = RESULT_PROBLEM_PARSING_NUMBER,
                    position = position,
                }
            end

            local function make_problem_unexpected_char(position, c)
                return {
                    result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                    position = position,
                    value = c
                }
            end

            local digit_parser = tt_urn.one_of(id, {
                tt_urn.char(id, '0'),
                tt_urn.char(id, '1'),
                tt_urn.char(id, '2'),
                tt_urn.char(id, '3'),
                tt_urn.char(id, '4'),
                tt_urn.char(id, '5'),
                tt_urn.char(id, '6'),
                tt_urn.char(id, '7'),
                tt_urn.char(id, '8'),
                tt_urn.char(id, '9'),
            })

            local function make_num(parsed_data, parsed_digits)
                if parsed_data.parse_type == tt_urn.PARSE_FAILURE then
                    return make_problem_make_num(parsed_data.position)
                end
                return make_success(tonumber(table.concat(parsed_digits)))
            end

            local make_tuple = function(parsed_data, parsed_nums)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return make_success({parsed_nums[1].value, parsed_nums[2].value})
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                else -- we failed. it's either us, or a contained parser failed
                    if parsed_nums == nil then
                        -- if the contained parsers are nil, it means we failed
                        -- at this level, so treat it as a generic "unexpected char"
                        -- problem
                        return make_problem_unexpected_char(parsed_data.position, parsed_data.char)
                    end
                    -- otherwise, one of the contained parsers failed, so just 
                    -- return what it gives us because that's already wrapped
                    -- in a `make_problem_make_num`
                    return parsed_nums
                end
            end

            local number_parser = tt_urn.one_or_more(make_num, digit_parser)

            local tuple_parser = tt_urn.sequence(make_tuple, {
                tt_urn.char(di, '('),
                tt_urn.zero_or_more(di, tt_urn.char(di, ' ')),
                number_parser,
                tt_urn.zero_or_more(di, tt_urn.char(di, ' ')),
                tt_urn.char(di, ','),
                tt_urn.zero_or_more(di, tt_urn.char(di, ' ')),
                number_parser,
                tt_urn.zero_or_more(di, tt_urn.char(di, ' ')),
                tt_urn.char(di, ')'),
            })


            -- success
            local success_parse_data, success_value = tt_urn.run(tuple_parser, "(12, 34    )")
            assert.is_same(success_parse_data, {
                parse_type = tt_urn.PARSE_SUCCESS,
                offset = 13,
                position_start = {
                    row = 1,
                    column = 1,
                },
                position_end = {
                    row = 1,
                    column = 13,
                }
            })
            assert.is_same(success_value, {
                result_type = RESULT_SUCCESS,
                value = { 12, 34 }
            })

            -- failure parsing number
            local failure_number_parse_data, failure_number = tt_urn.run(tuple_parser, "(12, a)")
            assert.is_same(failure_number_parse_data, {
                parse_type = tt_urn.PARSE_FAILURE,
                char = "a",
                offset = 6,
                position = {
                    row = 1,
                    column = 6,
                }
            })
            assert.is_same(failure_number, {
                result_type = RESULT_PROBLEM_PARSING_NUMBER,
                position = {
                    row = 1,
                    column = 6,
                }
            })

            -- failure parsing tuple
            local failure_tuple_parse_data, failure_tuple = tt_urn.run(tuple_parser, "(12 34)")
            assert.is_same(failure_tuple_parse_data, {
                parse_type = tt_urn.PARSE_FAILURE,
                char = '3',
                offset = 5,
                position = {
                    row = 1,
                    column = 5,
                }
            })
            assert.is_same(failure_tuple, {
                result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                position = {row = 1, column = 5},
                value = "3",
            })

            -- failure end of file
            local failure_eof_parse_data, failure_eof = tt_urn.run(tuple_parser, "(12")
            assert.is_same(failure_eof_parse_data, {
                parse_type = tt_urn.PARSE_FAILURE_EOF,
                offset = 4,
                position = {
                    row = 1,
                    column = 4,
                }
            })
            assert.is_same(failure_eof, {
                result_type = RESULT_PROBLEM_EOF,
                position = { row = 1, column = 4 }
            })

        end
    )


    it(
        [[\
        parses 'maybe' parsers, and fails correctly when it should
        ]],
        function()

            local whitespace = tt_urn.char(di, ' ')

            local function get_el_from_seq(parsed_data, a)
                return a[1]
            end

            local spaced_or_not = tt_urn.sequence(get_el_from_seq, {
                tt_urn.maybe(di, whitespace),
                tt_urn.char(id, 'a'),
                tt_urn.maybe(di, whitespace)
            })

            local function make_test(result)
                return function(input)
                    local _, value = tt_urn.run(spaced_or_not, input)
                    assert(result == value)
                end
            end

            local test = make_test("a")
            test("a")
            test("a ")
            test(" a ")
            test(" a")

        end
    )

    it(
        [[\
        parses a list of numbers of the form "[ 17, 18, 23, 24 ]", discarding
        what's not needed, keeps the digits, allows you to turn the digits
        to numbers and put them all in a table, and returns the table to you
        ]],
        function()

            local RESULT_SUCCESS = 1
            local RESULT_PROBLEM_EOF = 2
            local RESULT_PROBLEM_PARSING_NUMBER = 3
            local RESULT_PROBLEM_UNEXPECTED_CHAR = 4

            local function make_success(position, val)
                return {
                    result_type = RESULT_SUCCESS,
                    position = position,
                    value = val
                }
            end
            local function make_problem_eof(position)
                return {
                    result_type = RESULT_PROBLEM_EOF,
                    position = position,
                }
            end
            local function make_problem_parsing_number(position, chr)
                return {
                    result_type = RESULT_PROBLEM_PARSING_NUMBER,
                    position = position,
                    value = chr,
                }
            end
            local function make_problem_unexpected_char(position, chr)
                return {
                    result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                    position = position,
                    value = chr,
                }
            end

            local whitespace = tt_urn.char(di, ' ')

            local digit_parser = tt_urn.one_of(id, {
                tt_urn.char(id, '0'),
                tt_urn.char(id, '1'),
                tt_urn.char(id, '2'),
                tt_urn.char(id, '3'),
                tt_urn.char(id, '4'),
                tt_urn.char(id, '5'),
                tt_urn.char(id, '6'),
                tt_urn.char(id, '7'),
                tt_urn.char(id, '8'),
                tt_urn.char(id, '9'),
            })

            local function make_num(parsed_data, parsed_digits)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return tonumber(table.concat(parsed_digits))
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                end
                return make_problem_parsing_number(parsed_data.position, parsed_data.char)
            end

            local function make_element(parsed_data, parsed_num)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return parsed_num[1]
                end
                return parsed_num
            end

            -- if this fails, it can only be because one of the contained 
            -- parsers failed. so always just return the els, which will
            -- either be a success or failure
            local function propagate_elements(_, els)
                return els
            end

            local function make_list(parsed_data, things)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return things[1]
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                else -- failure. either we failed, or a contained parser
                    if things == nil then -- we failed
                        make_problem_unexpected_char(parsed_data.position, parsed_data.char)
                    else -- we succeeded. one of the contained parser failed
                        return things
                    end
                end
            end

            local number_parser = tt_urn.one_or_more(make_num, digit_parser)
            local element_parser = tt_urn.sequence(make_element, {
                number_parser,
            })

            local many_elements_parser = tt_urn.zero_or_more(propagate_elements,
                element_parser,
                tt_urn.sequence(di, {
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.char(di, ','),
                    tt_urn.zero_or_more(di, whitespace),
                })
            )

            local list_parser = tt_urn.sequence(make_list, {
                tt_urn.char(di, '['),
                tt_urn.zero_or_more(di, whitespace),
                many_elements_parser,
                tt_urn.zero_or_more(di, whitespace),
                tt_urn.char(di, ']')
            })

            local function make_test(result)
                return function (input)
                    local parsed_data, parsed_result = tt_urn.run(list_parser, input)
                    assert.is_same(parsed_result, result)
                end
            end

            local test_a = make_test({ 22 })
            test_a("[22]")
            test_a("[ 22]")
            test_a("[ 22 ]")
            test_a("[ 22     ]")
            local test_b = make_test({ 22, 33, 44 })
            test_b("[22,33,44]")
            test_b("[22,33,44 ]")
            test_b("[  22    , 33 , 44 ]")

            local fail_eof_parse_data, fail_eof_result = tt_urn.run(list_parser, "[ 12")
            assert.is_same(fail_eof_parse_data, {
                offset = 5,
                parse_type = tt_urn.PARSE_FAILURE_EOF,
                position = {
                    row = 1,
                    column = 5,
                }
            })
            assert.is_same(fail_eof_result, {
                result_type = RESULT_PROBLEM_EOF,
                position = {
                    row = 1,
                    column = 5,
                }
            })

            local fail_number_parse_data, fail_number = tt_urn.run(list_parser, "[ a ]")
            assert.is_same(fail_number_parse_data, {
                char = 'a',
                offset = 3,
                parse_type = tt_urn.PARSE_FAILURE,
                position = {
                    row = 1,
                    column = 3,
                }
            })
            assert(fail_number == nil)

        end
    )


    it(
        [[\
        parses nested lists like "[ [] ]"
        ]],
        function()

            local whitespace = tt_urn.one_of(di, {
                tt_urn.char(di, ' '),
                tt_urn.char(di, '\n')
            })

            local function _id(p, v)
            end

            local list_parser

            local function make_list(parsed_data, p)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    -- since this will be used in a sequence, the sequence does the
                    -- work of putting things in a list for us. so just return that
                    if p[1] == nil then
                        return {}
                    else
                        return p[1]
                    end
                end
            end

            list_parser = function()
                return tt_urn.sequence(make_list, {
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.char(di,'['),
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.zero_or_more(id, list_parser),
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.char(di, ']'),
                    tt_urn.zero_or_more(di, whitespace),
                })()
            end

            local function make_test(result)
                return function(input)
                    local _, res = tt_urn.run(list_parser, input)
                    assert.is_same(res, result)
                end
            end


            local test1 = make_test({})
            test1("[]")
            test1("[ ]")
            test1(" [ ] ")
            test1(" [  \n  ] ")

            local test = make_test({
                { },
                {
                    {}
                }
            })

            test("[[][[]]]")
            test("[[] [[]] ]")
            test("[ [] [[]] ]")
            test("[ [] [ []] ]")
            test("[ [] [ [] ] ]")
            test("[ [ ] [ [ ] ] ]")
            test([[
                [
                    [ ]    
                    [   
                        [ ] 
                    ]    
                ]     
            ]])
        end
    )

    it(
        [[\
        parses a list that can contain either numbers, or nested lists, like
        "[ 17, [ 18 ] ]", discards what's not needed, keeps the digits and the
        lists, allows you to turn the digits to numbers and the lists to tables,
        and returns the root table to you
        ]],
        function()

            local RESULT_SUCCESS = 1
            local RESULT_PROBLEM_EOF = 2
            local RESULT_PROBLEM_PARSING_NUMBER = 3
            local RESULT_PROBLEM_UNEXPECTED_CHAR = 4

            local function make_success(position, val)
                return {
                    result_type = RESULT_SUCCESS,
                    position = position,
                    value = val
                }
            end
            local function make_problem_eof(position)
                return {
                    result_type = RESULT_PROBLEM_EOF,
                    position = position,
                }
            end
            local function make_problem_parsing_number(position, chr)
                return {
                    result_type = RESULT_PROBLEM_PARSING_NUMBER,
                    position = position,
                    value = chr,
                }
            end
            local function make_problem_unexpected_char(position, chr)
                return {
                    result_type = RESULT_PROBLEM_UNEXPECTED_CHAR,
                    position = position,
                    value = chr,
                }
            end

            local whitespace = tt_urn.char(di, ' ')

            local digit_parser = tt_urn.one_of(id, {
                tt_urn.char(id, '0'),
                tt_urn.char(id, '1'),
                tt_urn.char(id, '2'),
                tt_urn.char(id, '3'),
                tt_urn.char(id, '4'),
                tt_urn.char(id, '5'),
                tt_urn.char(id, '6'),
                tt_urn.char(id, '7'),
                tt_urn.char(id, '8'),
                tt_urn.char(id, '9'),
            })

            local function make_num(parsed_data, parsed_digits)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return tonumber(table.concat(parsed_digits))
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                end
                return make_problem_parsing_number(parsed_data.position, parsed_data.char)
            end

            -- if this fails, it can only be because one of the contained 
            -- parsers failed. so always just return the els, which will
            -- either be a success or failure
            local function propagate_elements(_, els)
                return els
            end

            local function make_list(parsed_data, things)
                if parsed_data.parse_type == tt_urn.PARSE_SUCCESS then
                    return things[1]
                elseif parsed_data.parse_type == tt_urn.PARSE_FAILURE_EOF then
                    return make_problem_eof(parsed_data.position)
                else -- failure. either we failed, or a contained parser
                    if things == nil then -- we failed
                        make_problem_unexpected_char(parsed_data.position, parsed_data.char)
                    else -- we succeeded. one of the contained parser failed
                        return things
                    end
                end
            end

            local list_parser
            local value_parser

            local number_parser = tt_urn.one_or_more(make_num, digit_parser)

            value_parser = function()
                return tt_urn.one_of(id, {
                    list_parser,
                    number_parser,
                })()
            end


            local many_values_parser = tt_urn.zero_or_more(propagate_elements,
                value_parser,
                tt_urn.sequence(di, {
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.char(di, ','),
                    tt_urn.zero_or_more(di, whitespace),
                })
            )

            list_parser = function()
                return tt_urn.sequence(make_list, {
                    tt_urn.char(di, '['),
                    tt_urn.zero_or_more(di, whitespace),
                    many_values_parser,
                    tt_urn.zero_or_more(di, whitespace),
                    tt_urn.char(di, ']')
                })()
            end

            local function make_test(result)
                return function (input)
                    local _, parsed_result = tt_urn.run(list_parser, input)
                    assert.is_same(parsed_result, result)
                end
            end

            local test_a = make_test({ 22 })
            test_a("[22]")
            test_a("[ 22]")
            test_a("[ 22 ]")
            test_a("[ 22     ]")

            local test_b = make_test({ 22, 33, 44 })
            test_b("[22,33,44]")
            test_b("[22,33,44 ]")
            test_b("[  22    , 33 , 44 ]")

            local test_c = make_test({ 22, {33} })
            test_c("[22,[33]]")
            test_c("[ 22   ,    [ 33 ] ]")

            local test_d = make_test({ 22, {{{33}}} })
            test_d("[22,[[[33]]]]")
            test_d("[ 22   ,    [[[ 33 ]] ] ]")

            local fail_eof_parse_data, fail_eof_result = tt_urn.run(list_parser, "[ 12")
            assert.is_same(fail_eof_parse_data, {
                offset = 5,
                parse_type = tt_urn.PARSE_FAILURE_EOF,
                position = {
                    row = 1,
                    column = 5,
                }
            })
            assert.is_same(fail_eof_result, {
                result_type = RESULT_PROBLEM_EOF,
                position = {
                    row = 1,
                    column = 5,
                }
            })

            local fail_number_parse_data, fail_number = tt_urn.run(list_parser, "[ a ]")
            assert.is_same(fail_number_parse_data, {
                char = 'a',
                offset = 3,
                parse_type = tt_urn.PARSE_FAILURE,
                position = {
                    row = 1,
                    column = 3,
                }
            })
            assert(fail_number == nil)

        end
    )

end)
