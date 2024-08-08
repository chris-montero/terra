
#include <stdlib.h> // for `exit`

#include <lua.h>
#include <lauxlib.h>

#include "lhelp.h"

#include "application.h"
#include "app.h"
#include "util.h"
#include "sane.h"

// from luajit source code. Copyright Mike Pall.
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

int lhelp_start_app(lua_State *L)
{
    // the top function should be the event handler supplied to us by the user.
    // we don't need it now, so put it in the registry.
    lua_setfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY);

    // by this point, we should only be left with one function on the stack:
    // the model initializing function

    // push the on_runtime_error function at the beginning of the stack
    lua_pushcfunction(L, lhelp_function_on_runtime_error);
    lua_insert(L, 1);

    // finally, run the model initializing function, which should return 
    // to us with the model.
    lua_pushlightuserdata(L, &app);
    int runtime_error = lua_pcall(L, 1, 1, 1);
    if (runtime_error != 0) return runtime_error;

    // then keep the model safe by storing it into the lua registry
    lua_setfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_MODEL_KEY);

    // remove `lhelp_function_on_runtime_error` function
    lua_remove(L, 1); 
    return 0;
}

// this function will create the error message in the case there's a 
// runtime error when the config file is first run.
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

// setup the lua equivalent of `event_handler(app, model, <empty>`
// the <empty> should be pushed by the user of this function. This is
// usually done in the event handling portion of the C code
void lhelp_setup_event_handler(lua_State *L)
{
    lua_pushcfunction(L, lhelp_function_on_runtime_error);
    lua_getfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY);
    lua_pushlightuserdata(L, &app);
    lua_getfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_MODEL_KEY);
}

// after calling `lhelp_setup_event_handler`, and pushing onto the stack the 
// desired event, you can call this function to have it automatically call
// the event handler properly
void lhelp_call_event_handler(lua_State *L, uint nr_params)
{
    // +2 because we also call the function with the <terra_data> 
    // and <terra.app>.
    int runtime_error = lua_pcall(L, nr_params + 2, 0, 1);
    if (runtime_error != 0) {
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
        lua_pop(L, 1); // pop error message
    }
    lua_pop(L, 1); // pop the error function
}

struct Application *lhelp_check_app(lua_State *L, int ind)
{
    struct Application *ap = (struct Application *)lua_touserdata(L, ind);
    if (ap == NULL) {
        printf("TERRA ERROR - supplied argument is not an 'Application': %s.\n", lua_tostring(L, ind));
        util_backtrace_print();
        exit(1);
    }
    return ap;
}

void lhelp_push_id(lua_State *L, u32 x_id)
{
    lua_pushinteger(L, x_id);
    lua_tostring(L, -1); // convert the id to a lua string
}

u32 lhelp_check_id(lua_State *L, i32 ind)
{
    u32 id = lua_tointeger(L, ind);
    if (id == 0) {
        // TODO: dostring("debug.traceback")
        printf("TERRA ERROR - invalid id: %s. (TODO: print a traceback)\n", lua_tostring(L, ind));
        util_backtrace_print();
        exit(1);
    }
    return id;
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
