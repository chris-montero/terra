
#include <lua.h>
#include <lauxlib.h>

#include "lhelp.h"

#include "sane.h"

// from luajit source code. Copyright Mike Pall. (probably copy pasted from lua5.2 lol)
void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup)
{
  luaL_checkstack(L, nup, "too many upvalues");
  for (; l->name; l++) {
    int i;
    for (i = 0; i < nup; i++)  /* Copy upvalues to the top. */
      lua_pushvalue(L, -nup);
    lua_pushcclosure(L, l->func, nup);
    lua_setfield(L, -(nup + 2), l->name);
  }
  lua_pop(L, nup);  /* Remove upvalues. */
}

void lhelp_dump_stack(lua_State *L)
{
    uint i = lua_gettop(L);
    fprintf(stderr, "LUA STACK DUMP START: \n");
    while (i != 0) {
        uint t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING:
                fprintf(stderr, "%d\t string: %s\n", i, lua_tostring(L, i));
                break;
            case LUA_TBOOLEAN:
                fprintf(stderr, "%d\t boolean: %s", i, lua_toboolean(L, i) ? "true\n" : "false\n");
                break;
            case LUA_TNUMBER:
                fprintf(stderr, "%d\t number: %g\n", i, lua_tonumber(L, i));
                break;
            case LUA_TNIL:
                fprintf(stderr, "%d\t nil\n", i);
                break;
            case LUA_TTABLE:
                fprintf(stderr, "%d\t table(%p); length: %lu\n", i, lua_topointer(L, i), lua_objlen(L, i));
                break;
            default:
                fprintf(
                    stderr,
                    "%d\t %s(%p); length: %lu\n",
                    i,
                    lua_typename(L, t),
                    lua_topointer(L, i),
                    lua_objlen(L, i)
                );
                break;
        }
        i--;
    }
    fprintf(stderr, "\nLUA STACK DUMP END \n");
}

// the default runtime error function
int lhelp_function_on_runtime_error(lua_State *L)
{
    // push the `deubg.traceback` function on the stack
    lua_getglobal(L, "debug");
    lua_pushstring(L, "traceback");
    lua_rawget(L, -2);
    lua_remove(L, -2); // remove the debug library

    // push the return value of `debug.traceback(<original_error_msg>, 1)` on the stack
    lua_tostring(L, 1); // make sure the error is a string
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 1);
    lua_call(L, 2, 1);

    // remove the original message
    lua_remove(L, 1); 

    // now create a message like:
    // ----------------- RUNTIME ERROR -----------------
    // <the runtime error message>
    lua_pushstring(L, "\n----------------- RUNTIME ERROR -----------------\n");
    lua_insert(L, 1);
    lua_pushstring(L, "\n\n");
    lua_concat(L, 3);

    // the error string we created is still on the stack
    return 1;
}

// does t[`name`] = `b` where "t" is the table on top of the stack
void lhelp_set_bool(lua_State *L, char *name, bool b)
{
    lua_pushstring(L, name);
    lua_pushboolean(L, b);
    lua_rawset(L, -3);
}

// does t[`name`] = `i` where "t" is the table on top of the stack
void lhelp_set_int(lua_State *L, char *name, int i)
{
    lua_pushstring(L, name);
    lua_pushinteger(L, i);
    lua_rawset(L, -3);
}

// does t[`name`] = `value` where "t" is the table on top of the stack
void lhelp_set_string(lua_State *L, char *name, char *value)
{
    lua_pushstring(L, name);
    lua_pushstring(L, value);
    lua_rawset(L, -3);
}
