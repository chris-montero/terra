
#include <lua.h>
#include <lauxlib.h>

#include "application.h"
#include "sane.h"

#define TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY "terra_application_lua_event_handler"
#define TERRA_LUA_REGISTRY_MODEL_KEY "terra_application_lua_model"

// from lua5.2. In spite of the fact that we use luajit, which defines these
// macros, we use luarocks to compile the project, which uses lua5.1's
// headers. What this means is that we have to define these ourselves to 
// ensure compatibility with lua5.1.
void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup);
#define luaL_newlibtable(L, l) \
	lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)
#define luaL_newlib(L, l)	(luaL_newlibtable(L, l), luaL_setfuncs(L, l, 0))

void lhelp_dump_stack(lua_State *L);
int lhelp_start_app(lua_State *L);
int lhelp_function_on_runtime_error(lua_State *L);

void lhelp_setup_event_handler(lua_State *L);
void lhelp_call_event_handler(lua_State *L, uint nr_parameters);

struct Application *lhelp_check_app(lua_State *L, int ind);

u32 lhelp_check_id(lua_State *L, i32 ind);
void lhelp_push_id(lua_State *L, u32 x_id);

void lhelp_set_bool(lua_State *L, char *name, bool b);
void lhelp_set_int(lua_State *L, char *name, int i);
void lhelp_set_string(lua_State *L, char *name, char *value);

