
local tt_sstr = require("terra.tools.sstr")

describe("sstr", function() 

    describe("from_string", function() 
        it("correctly creates a sstr from a lua string", function()
            assert.is_same(tt_sstr.from_string("hello"), {'h', 'e', 'l', 'l', 'o'})
        end)
    end)

    describe("to_string", function() 
        it("correctly converts a 'sstr' back into a lua string", function()
            assert.is_same(tt_sstr.to_string({'h', 'e', 'l', 'l', 'o'}), "hello")
        end)
    end)

    describe("length", function() 
        it("returns the correct length", function()
            assert.equals(tt_sstr.length(tt_sstr.from_string("hello wordl")), 11)
        end)
    end)

    describe("slice", function() 
        it("returns nil if p2 is smaller than p1", function()
            assert.is_true(tt_sstr.slice(tt_sstr.from_string("hello"), 4, 2) == nil)
        end)
        it("returns nil if p1 is bigger than the length of the value", function()
            assert.is_true(tt_sstr.slice(tt_sstr.from_string("hello"), 8, 9) == nil)
        end)
        it("clamps p2 if it's longer than the length of the string", function()
            assert.is_same(tt_sstr.slice(tt_sstr.from_string("hello"), 2, 8), {'e', 'l', 'l', 'o'})
        end)
        it("returns the correct result when it should", function()
            assert.is_same(tt_sstr.slice(tt_sstr.from_string("hello"), 2, 3), {'e', 'l'})
        end)
    end)

    describe("starts_with", function() 
        it("returns false if second parameter is longer than the first", function()
            assert.is_false(tt_sstr.starts_with(tt_sstr.from_string("/home"), tt_sstr.from_string("/home/dir")))
        end)
        it("returns true when it should", function()
            assert.is_true(tt_sstr.starts_with(tt_sstr.from_string("/home/dir"), tt_sstr.from_string("/home")))
        end)
        it("returns false when it should", function()
            assert.is_false(tt_sstr.starts_with(tt_sstr.from_string("/home/dir"), tt_sstr.from_string("no")))
        end)
    end)

    describe("ends_with", function() 
        it("returns false if second parameter is longer than the first", function()
            assert.is_false(tt_sstr.ends_with(tt_sstr.from_string("/home"), tt_sstr.from_string("/home/dir")))
        end)
        it("returns true when it should", function()
            assert.is_true(tt_sstr.ends_with(tt_sstr.from_string("/home/dir"), tt_sstr.from_string("dir")))
        end)
        it("returns false when it should", function()
            assert.is_false(tt_sstr.ends_with(tt_sstr.from_string("/home/dir"), tt_sstr.from_string("no")))
        end)
    end)

    describe("find_iter", function() 
        it("do", function()
            local to_compare = {1, 11, 17, 24}
            local result = {}
            for i in tt_sstr.find_iter(tt_sstr.from_string("__grabbing__your__gyatt__"), tt_sstr.from_string('__')) do
                table.insert(result, i)
            end
            assert.is_same(to_compare, result)
        end)
    end)

    describe("split_iter", function() 
        it("returns the original sstr if there's no separator", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("lmao"), tt_sstr.from_string('/')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("lmao")})
        end)
        it("correctly discards the separator if the sstr starts with it", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("/home"), tt_sstr.from_string('/')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("home")})
        end)
        it("correctly discards the separator if the sstr starts with it multiple consecutive times", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("//home"), tt_sstr.from_string('/')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {{}, tt_sstr.from_string("home")})
        end)
        it("correctly splits a sstr even if it ends with the separator", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("home/"), tt_sstr.from_string('/')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("home")})
        end)
        it("correctly splits a sstr even if it ends with the separator multiple consecutive times", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("home//"), tt_sstr.from_string('/')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("home"), {}})
        end)
        it("correctly splits a simple sstr", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("__a__"), tt_sstr.from_string('__')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("a")})
        end)
        it("correctly splits a more complex sstr", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("__a__b__"), tt_sstr.from_string('__')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {tt_sstr.from_string("a"), tt_sstr.from_string("b")})
        end)
        it("correctly splits a complex sstr", function()
            local res = {}
            for sstr_value in tt_sstr.split_iter(tt_sstr.from_string("__ab_b__c__d_eb_"), tt_sstr.from_string('_')) do
                table.insert(res, sstr_value)
            end
            assert.is_same(res, {
                {},
                tt_sstr.from_string("ab"),
                tt_sstr.from_string("b"),
                {},
                tt_sstr.from_string("c"),
                {},
                tt_sstr.from_string("d"),
                tt_sstr.from_string("eb"),
            })
        end)
    end)

end)

