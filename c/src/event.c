
#include <xcb/xcb.h>

#ifdef DEBUG
#include <xcb/xcb_errors.h>
#endif 

// #include "atoms.h"
#include "util.h"
// #include "window.h"
#include "terra_xkb.h"
#include "lhelp.h"
#include "sane.h"
#include "app.h"

// // TODO: move these to "lhelp.c"
// // expects on top of the stack the table to set the number on
// void _setint(lua_State *L, char *field, int num)
// {
//     lua_pushstring(L, field);
//     lua_pushinteger(L, num);
//     lua_rawset(L, -3);
// }
//
// // expects the table to set the type on on top of the stack 
// void _settype(lua_State *L, char *event_type)
// {
//     lua_pushstring(L, "type");
//     lua_pushstring(L, event_type);
//     lua_rawset(L, -3);
// }
//
// void _setstr(lua_State *L, char *field, char *value)
// {
//     lua_pushstring(L, field);
//     lua_pushstring(L, value);
//     lua_rawset(L, -3);
// }
//
// void _setid(lua_State *L, char *field, u32 id)
// {
//     lua_pushstring(L, field);
//     lhelp_push_id(L, id);
//     lua_rawset(L, -3);
// }

static void handle_button_event(xcb_button_press_event_t *e)
{
    // TODO: implement this properly
    // TODO: we probably care about the modifiers on click press, so we should send the full e->state through
    // e->state uses the first 8 bits for the button status and the last 
    // 8 bits for the modifiers status. erase the button status because we 
    // don't need it.
    e->state &= 0x00ff;

    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_ClickEvent"); // event_type
    lhelp_push_id(app.L, e->event); // window_id
    lua_pushboolean(app.L, e->response_type == XCB_BUTTON_PRESS); // is_press
    lua_pushinteger(app.L, e->detail); // button
    lua_pushinteger(app.L, e->state); // modifiers
    lua_pushinteger(app.L, e->event_x); // x
    lua_pushinteger(app.L, e->event_y); // y
    // lua_pushinteger(app.L, "root_x", e->root_x);
    // lua_pushinteger(app.L, "root_y", e->root_y);

    lhelp_call_event_handler(app.L, 7);
}

void handle_configure_notify(xcb_configure_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_ConfigureNotify"); // event_type
    lhelp_push_id(app.L, e->window); // window_id
    lua_pushinteger(app.L, e->x); // x
    lua_pushinteger(app.L, e->y); // y
    lua_pushinteger(app.L, e->width); // width
    lua_pushinteger(app.L, e->height); // height
    // lua_pushinteger(app.L, e->border_width);

    lhelp_call_event_handler(app.L, 6);
}

void handle_create_notify(xcb_create_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_CreateNotify"); // event_type
    lhelp_push_id(app.L, e->parent); // parent_id
    lhelp_push_id(app.L, e->window); // window_id
    lua_pushinteger(app.L, e->x); // x
    lua_pushinteger(app.L, e->y); // y 
    lua_pushinteger(app.L, e->width); // width
    lua_pushinteger(app.L, e->height); // height
    // lua_pushinteger(app.L, e->border_width);

    lhelp_call_event_handler(app.L, 7);
}

static void handle_destroy_notify(xcb_destroy_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_DestroyNotify"); // event_type
    lhelp_push_id(app.L, e->event); // parent_id
    lhelp_push_id(app.L, e->window); // window_id

    lhelp_call_event_handler(app.L, 3);
}

static void handle_enter_notify(xcb_enter_notify_event_t *e)
{
    // TODO: there's probably data about modifiers in here; send them as well.
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_EnterNotify"); // event_type
    // lhelp_push_id(app.L, e->root);
    // if (e->child != XCB_NONE) {
    //     lhelp_push_id(app.L, e->child);
    // }
    lhelp_push_id(app.L, e->event); // window_id
    lua_pushinteger(app.L, e->detail); // button
    lua_pushinteger(app.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(app.L, e->event_x); // x
    lua_pushinteger(app.L, e->event_y); // y
    // lua_pushinteger(app.L, e->root_x);
    // lua_pushinteger(app.L, e->root_y);

    lhelp_call_event_handler(app.L, 6);
}

static void handle_expose_event(xcb_expose_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_ExposeEvent"); // event_type
    lhelp_push_id(app.L, e->window); // window_id
    lua_pushinteger(app.L, e->x); // x
    lua_pushinteger(app.L, e->y); // y
    lua_pushinteger(app.L, e->width); // width
    lua_pushinteger(app.L, e->height); // height
    lua_pushinteger(app.L, e->count); // count

    lhelp_call_event_handler(app.L, 7);
}

static void handle_focus_in(xcb_focus_in_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_FocusIn"); // event_type
    lhelp_push_id(app.L, e->event); // window_id

    lhelp_call_event_handler(app.L, 2);
}

static void handle_focus_out(xcb_focus_out_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_FocusOut"); // event_type
    lhelp_push_id(app.L, e->event); // window_id

    lhelp_call_event_handler(app.L, 2);
}

// static void handle_graphics_exposure_event(xcb_graphics_exposure_event_t *e)
// {
//     lhelp_setup_event_handler(app.L);
//
//     lua_newtable(app.L);
//     _settype(app.L, "X_GraphicsExposureEvent");
//
//     lhelp_push_id(app.L, e->drawable);
//
//     lua_pushinteger(app.L, e->x);
//     lua_pushinteger(app.L, e->y);
//     lua_pushinteger(app.L, e->width);
//     lua_pushinteger(app.L, e->height);
//     lua_pushinteger(app.L, e->count);
//
//     lhelp_call_event_handler(app.L);
// }


static void handle_key_event(xcb_key_press_event_t *e)
{
    // TODO: clean this up
	// xcb_keysym_t keysym = util_xcb_keycode_to_keysym(e->detail);
    // FIXME: when you press a control character like "Control_L" the 
    // modifiers are '0', but when you release it, the modifiers are '4'.
    // I'm not even sure if this needs to be fixed or not.
    struct Keybuffer keybuf = terra_xkb_keycode_to_string(e->detail);

    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_KeyEvent"); // event_type
    lhelp_push_id(app.L, e->event); // window_id
    lua_pushboolean(app.L, e->response_type == XCB_KEY_PRESS); // is_press
    lua_pushstring(app.L, keybuf.key_str); // key
    lua_pushinteger(app.L, e->state); // modifiers

    lhelp_call_event_handler(app.L, 5);
}

static void handle_leave_notify(xcb_enter_notify_event_t *e)
{
    // TODO: there's probably data about modifiers in here; send them as well.
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_LeaveNotify"); // event_type
    lhelp_push_id(app.L, e->event); // window_id
    // lhelp_push_id(app.L, e->root);
    // if (e->child != XCB_NONE) {
    //     lhelp_push_id(app.L, e->child);
    // }

    lua_pushinteger(app.L, e->detail); // button
    lua_pushinteger(app.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(app.L, e->event_x); // x
    lua_pushinteger(app.L, e->event_y); // y
    // lua_pushinteger(app.L, e->root_x);
    // lua_pushinteger(app.L, e->root_y);

    lhelp_call_event_handler(app.L, 6);
}

static void handle_motion_notify(xcb_motion_notify_event_t *e)
{
    // TODO: there's probably data about button and modifiers in here; send them as well.
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_MotionEvent"); // event_type
    lhelp_push_id(app.L, e->event); // window_id

    lua_pushinteger(app.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(app.L, e->event_x); // x
    lua_pushinteger(app.L, e->event_y); // y
    // lua_pushinteger(app.L, e->root_x);
    // lua_pushinteger(app.L, e->root_y);

    lhelp_call_event_handler(app.L, 5);
}

static void handle_map_notify(xcb_map_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_MapNotify"); // event_type
    // lhelp_push_id(app.L, "event_window_id", e->event);
    lhelp_push_id(app.L, e->window); // window_id

    lhelp_call_event_handler(app.L, 2);
}

static void handle_map_request(xcb_map_request_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_MapRequest"); // event_type
    lhelp_push_id(app.L, e->parent); // parent_id
    lhelp_push_id(app.L, e->window); // window_id

    lhelp_call_event_handler(app.L, 3);
}

void handle_property_notify(xcb_property_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_PropertyNotify"); // event_type
    lhelp_push_id(app.L, e->window); // window_id
    lua_pushinteger(app.L, e->atom); // atom
    // TODO: Do I really need to send the time ?
    lua_pushinteger(app.L, e->time); // time
    lua_pushinteger(app.L, e->state); // state

    lhelp_call_event_handler(app.L, 5);
}

void handle_reparent_notify(xcb_reparent_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_ReparentNotify"); // event_type

    lhelp_push_id(app.L, e->event); // event_window_id
    lhelp_push_id(app.L, e->parent); // parent_id
    lhelp_push_id(app.L, e->window); // window_id

    lua_pushinteger(app.L, e->x); // x
    lua_pushinteger(app.L, e->y); // y

    lhelp_call_event_handler(app.L, 6);
}

static void handle_visibility_notify(xcb_visibility_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_VisibilityNotify"); // event_type

    lhelp_push_id(app.L, e->window); // window_id
    lua_pushinteger(app.L, e->state); // visibility (0 == UNOBSCURED; 1 == PARTIALLY_OBSCURED; 2 == FULLY_OBSCURED)

    lhelp_call_event_handler(app.L, 3);
}

static void handle_unmap_notify(xcb_unmap_notify_event_t *e)
{
    lhelp_setup_event_handler(app.L);

    lua_pushstring(app.L, "X_UnmapNotify"); // event_type
    lhelp_push_id(app.L, e->window); // window_id

    lhelp_call_event_handler(app.L, 2);
}

void event_handle(xcb_generic_event_t *e)
{

    // Strip off the highest bit (set if the event is generated)
    e->response_type &= 0x7F; 

    // this is an error
    if (e->response_type == 0) {
#ifdef DEBUG
        util_xerror_handle((xcb_generic_error_t *) e);
        return;
#else
        generic_error_print((xcb_generic_error_t *) e);
        return;
#endif
    }

    switch(e->response_type) {

        case XCB_BUTTON_PRESS:
            handle_button_event((xcb_button_press_event_t *)e);
            break;
        case XCB_BUTTON_RELEASE:
            handle_button_event((xcb_button_release_event_t *)e);
            break;
        case XCB_CONFIGURE_NOTIFY:
            handle_configure_notify((xcb_configure_notify_event_t *)e);
            break;
        case XCB_CREATE_NOTIFY:
            handle_create_notify((xcb_create_notify_event_t *)e);
            break;
        case XCB_DESTROY_NOTIFY:
            handle_destroy_notify((xcb_destroy_notify_event_t *)e);
            break;
        case XCB_ENTER_NOTIFY:
            handle_enter_notify((xcb_enter_notify_event_t *)e);
            break;
        case XCB_EXPOSE:
            handle_expose_event((xcb_expose_event_t *)e);
            break;
        case XCB_FOCUS_IN:
            handle_focus_in((xcb_focus_in_event_t *)e);
            break;
        case XCB_FOCUS_OUT:
            handle_focus_out((xcb_focus_in_event_t *)e);
            break;
        // TODO: figure out if I need this anymore
        // case XCB_GRAPHICS_EXPOSURE:
        //     handle_graphics_exposure_event((xcb_graphics_exposure_event_t *)e);
        //     break;
        case XCB_KEY_PRESS:
            handle_key_event((xcb_key_press_event_t *)e);
            break;
        case XCB_KEY_RELEASE:
            handle_key_event((xcb_key_release_event_t *)e);
            break;
        case XCB_LEAVE_NOTIFY:
            handle_leave_notify((xcb_leave_notify_event_t *)e);
            break;
        case XCB_MOTION_NOTIFY:
            handle_motion_notify((xcb_motion_notify_event_t *)e);
            break;
        case XCB_MAP_NOTIFY:
            handle_map_notify((xcb_map_notify_event_t *)e);
            break;
        case XCB_MAP_REQUEST:
            handle_map_request((xcb_map_request_event_t *)e);
            break;
        case XCB_PROPERTY_NOTIFY:
            handle_property_notify((xcb_property_notify_event_t *)e);
            break;
        case XCB_REPARENT_NOTIFY:
            handle_reparent_notify((xcb_reparent_notify_event_t *)e);
            break;
        case XCB_VISIBILITY_NOTIFY:
            handle_visibility_notify((xcb_visibility_notify_event_t *)e);
            break;
        case XCB_UNMAP_NOTIFY:
            handle_unmap_notify((xcb_unmap_notify_event_t *)e);
            break;

        // TODO: implement
        // Mapping notify happens when keyboard mapping changed for example 
        // when using Xmodmap
        // - re-allocate keysyms (i think)
        // - re-grab bindings
        // case XCB_MAPPING_NOTIFY:
    }
}


