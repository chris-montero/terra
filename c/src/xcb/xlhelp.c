#ifndef XCB_XLHELP_H
#define XCB_XLHELP_H

#include <stdio.h>
#include <stdlib.h>

#include <lua.h>

#include "lhelp.h"
#include "util.h"
#include "sane.h"

#include "xcb/xlhelp.h"

struct XcbContext *xlhelp_check_xcb_ctx(lua_State *L, int ind)
{
    struct XcbContext *xc = (struct XcbContext *)lua_touserdata(L, ind);
    if (xc == NULL) {
        printf("TERRA ERROR - supplied argument is not an 'XcbContext': %s.\n", lua_tostring(L, ind));
        util_backtrace_print();
        exit(1);
    }
    return xc;
}

void xlhelp_push_id(lua_State *L, u32 x_id)
{
    lua_pushinteger(L, x_id);
    lua_tostring(L, -1); // convert the id to a lua string
}

u32 xlhelp_check_id(lua_State *L, i32 ind)
{
    u32 id = lua_tointeger(L, ind);
    if (id == 0) {
        // TODO: dostring("debug.traceback")
        printf("ERROR - invalid X11 id: %s. (TODO: print a traceback)\n", lua_tostring(L, ind));
        util_backtrace_print();
        exit(1);
    }
    return id;
}

// int lhelp_store_event_handler(lua_State *L)
// {
//     // the top function should be the event handler supplied to us by the user.
//     // we don't need it now, so put it in the registry.
//     lua_setfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY);
//
//     // by this point, we should only be left with one function on the stack:
//     // the model initializing function
//
//     // push the on_runtime_error function at the beginning of the stack
//     lua_pushcfunction(L, lhelp_function_on_runtime_error);
//     lua_insert(L, 1);
//
//     // finally, run the model initializing function, which should return 
//     // to us with the model.
//     lua_pushlightuserdata(L, &app);
//     int runtime_error = lua_pcall(L, 1, 1, 1);
//     if (runtime_error != 0) return runtime_error;
//
//     // then keep the model safe by storing it into the lua registry
//     lua_setfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_MODEL_KEY);
//
//     // remove `lhelp_function_on_runtime_error` function
//     lua_remove(L, 1); 
//     return 0;
// }

// setup the lua equivalent of `event_handler(xcb_ctx, model, <empty>`
// the <empty> should be pushed by the user of this function. This is
// usually done in the event handling portion of the C code
void xlhelp_setup_event_handler(lua_State *L)
{
    lua_pushcfunction(L, lhelp_function_on_runtime_error);
    lua_getfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY);
}

// after calling `lhelp_setup_event_handler`, and pushing onto the stack the 
// desired event, you can call this function to have it automatically call
// the event handler properly
void xlhelp_call_event_handler(lua_State *L, uint nr_params)
{
    int runtime_error = lua_pcall(L, nr_params, 0, 1);
    if (runtime_error != 0) {
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
        lua_pop(L, 1); // pop error message
    }
    lua_pop(L, 1); // pop the error function
}

#endif
