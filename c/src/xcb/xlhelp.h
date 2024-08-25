#ifndef TERRA_XCB_XLHELP_H
#define TERRA_XCB_XLHELP_H

#include <lua.h>
#include <lauxlib.h>

#include "sane.h"

#define TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY "terra_lua_event_handler"

struct XcbContext *xlhelp_check_xcb_ctx(lua_State *L, int ind);
u32 xlhelp_check_id(lua_State *L, i32 ind);
void xlhelp_push_id(lua_State *L, u32 x_id);

void xlhelp_setup_event_handler(lua_State *L);
void xlhelp_call_event_handler(lua_State *L, uint nr_parameters);

#endif
