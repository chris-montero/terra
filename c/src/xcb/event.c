
#include <xcb/xcb.h>

#ifdef DEBUG
#include <xcb/xcb_errors.h>
#endif 

#include "sane.h"

// #include "atoms.h"
#include "xcb/xutil.h"
#include "xcb/context.h"
#include "xcb/xcb_ctx.h"
#include "xcb/terra_xkb.h"
#include "xcb/xlhelp.h"

static int handle_button_event(xcb_button_press_event_t *e)
{
    // TODO: implement this properly
    // TODO: we probably care about the modifiers on click press, so we should send the full e->state through
    // e->state uses the first 8 bits for the button status and the last 
    // 8 bits for the modifiers status. erase the button status because we 
    // don't need it.
    e->state &= 0x00ff;

    lua_pushstring(xcb_ctx.L, "X_ClickEvent"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id
    lua_pushboolean(xcb_ctx.L, e->response_type == XCB_BUTTON_PRESS); // is_press
    lua_pushinteger(xcb_ctx.L, e->detail); // button
    lua_pushinteger(xcb_ctx.L, e->state); // modifiers
    lua_pushinteger(xcb_ctx.L, e->event_x); // x
    lua_pushinteger(xcb_ctx.L, e->event_y); // y
    // lua_pushinteger(xcb_ctx.L, "root_x", e->root_x);
    // lua_pushinteger(xcb_ctx.L, "root_y", e->root_y);

    return 7;
}

static int handle_configure_notify_event(xcb_configure_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_ConfigureNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->x); // x
    lua_pushinteger(xcb_ctx.L, e->y); // y
    lua_pushinteger(xcb_ctx.L, e->width); // width
    lua_pushinteger(xcb_ctx.L, e->height); // height
    // lua_pushinteger(xcb_ctx.L, e->border_width);

    return 6;
}

static int handle_create_notify_event(xcb_create_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_CreateNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->parent); // parent_id
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->x); // x
    lua_pushinteger(xcb_ctx.L, e->y); // y 
    lua_pushinteger(xcb_ctx.L, e->width); // width
    lua_pushinteger(xcb_ctx.L, e->height); // height
    // lua_pushinteger(xcb_ctx.L, e->border_width);

    return 7;
}

static int handle_destroy_notify_event(xcb_destroy_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_DestroyNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // parent_id
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id

    return 3;
}

static int handle_enter_notify_event(xcb_enter_notify_event_t *e)
{
    // TODO: there's probably data about modifiers in here; send them as well.

    lua_pushstring(xcb_ctx.L, "X_EnterNotify"); // event_type
    // xlhelp_push_id(xcb_ctx.L, e->root);
    // if (e->child != XCB_NONE) {
    //     xlhelp_push_id(xcb_ctx.L, e->child);
    // }
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id
    lua_pushinteger(xcb_ctx.L, e->detail); // button
    lua_pushinteger(xcb_ctx.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(xcb_ctx.L, e->event_x); // x
    lua_pushinteger(xcb_ctx.L, e->event_y); // y
    // lua_pushinteger(xcb_ctx.L, e->root_x);
    // lua_pushinteger(xcb_ctx.L, e->root_y);

    return 6;
}

static int handle_expose_event(xcb_expose_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_ExposeEvent"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->x); // x
    lua_pushinteger(xcb_ctx.L, e->y); // y
    lua_pushinteger(xcb_ctx.L, e->width); // width
    lua_pushinteger(xcb_ctx.L, e->height); // height
    lua_pushinteger(xcb_ctx.L, e->count); // count

    return 7;
}

static int handle_focus_in_event(xcb_focus_in_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_FocusIn"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id

    return 2;
}

static int handle_focus_out_event(xcb_focus_out_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_FocusOut"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id

    return 2;
}

// static int handle_graphics_exposure_event(xcb_graphics_exposure_event_t *e)
// {
//
//     lua_pushstring(xcb_ctx.L, "X_GraphicsExposureEvent");
//
//     xlhelp_push_id(xcb_ctx.L, e->drawable);
//
//     lua_pushinteger(xcb_ctx.L, e->x);
//     lua_pushinteger(xcb_ctx.L, e->y);
//     lua_pushinteger(xcb_ctx.L, e->width);
//     lua_pushinteger(xcb_ctx.L, e->height);
//     lua_pushinteger(xcb_ctx.L, e->count);
//
//     return 7;
// }


static int handle_key_event(xcb_key_press_event_t *e)
{
    // TODO: clean this up
	// xcb_keysym_t keysym = util_xcb_keycode_to_keysym(e->detail);
    // FIXME: when you press a control character like "Control_L" the 
    // modifiers are '0', but when you release it, the modifiers are '4'.
    // I'm not even sure if this needs to be fixed or not.
    struct Keybuffer keybuf = terra_xkb_keycode_to_string(e->detail);

    xlhelp_setup_event_handler(xcb_ctx.L);

    lua_pushstring(xcb_ctx.L, "X_KeyEvent"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id
    lua_pushboolean(xcb_ctx.L, e->response_type == XCB_KEY_PRESS); // is_press
    lua_pushstring(xcb_ctx.L, keybuf.key_str); // key
    lua_pushinteger(xcb_ctx.L, e->state); // modifiers

    return 5;
}

static int handle_leave_notify_event(xcb_enter_notify_event_t *e)
{
    // TODO: there's probably data about modifiers in here; send them as well.
    lua_pushstring(xcb_ctx.L, "X_LeaveNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id
    // xlhelp_push_id(xcb_ctx.L, e->root);
    // if (e->child != XCB_NONE) {
    //     xlhelp_push_id(xcb_ctx.L, e->child);
    // }
    lua_pushinteger(xcb_ctx.L, e->detail); // button
    lua_pushinteger(xcb_ctx.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(xcb_ctx.L, e->event_x); // x
    lua_pushinteger(xcb_ctx.L, e->event_y); // y
    // lua_pushinteger(xcb_ctx.L, e->root_x);
    // lua_pushinteger(xcb_ctx.L, e->root_y);
    return 6;
}

static int handle_motion_notify_event(xcb_motion_notify_event_t *e)
{
    // TODO: there's probably data about button and modifiers in here; send them as well.
    lua_pushstring(xcb_ctx.L, "X_MotionEvent"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // window_id
    lua_pushinteger(xcb_ctx.L, e->state & 0x00ff); // modifiers
    lua_pushinteger(xcb_ctx.L, e->event_x); // x
    lua_pushinteger(xcb_ctx.L, e->event_y); // y
    // lua_pushinteger(xcb_ctx.L, e->root_x);
    // lua_pushinteger(xcb_ctx.L, e->root_y);

    return 5;
}

static int handle_map_notify_event(xcb_map_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_MapNotify"); // event_type
    // xlhelp_push_id(xcb_ctx.L, "event_window_id", e->event);
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id

    return 2;
}

static int handle_map_request_event(xcb_map_request_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_MapRequest"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->parent); // parent_id
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id

    return 3;
}

static int handle_property_notify_event(xcb_property_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_PropertyNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->atom); // atom
    // TODO: Do I really need to send the time ?
    lua_pushinteger(xcb_ctx.L, e->time); // time
    lua_pushinteger(xcb_ctx.L, e->state); // state

    return 5;
}

static int handle_reparent_notify_event(xcb_reparent_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_ReparentNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->event); // event_window_id
    xlhelp_push_id(xcb_ctx.L, e->parent); // parent_id
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->x); // x
    lua_pushinteger(xcb_ctx.L, e->y); // y

    return 6;
}

static int handle_visibility_notify_event(xcb_visibility_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_VisibilityNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id
    lua_pushinteger(xcb_ctx.L, e->state); // visibility (0 == UNOBSCURED; 1 == PARTIALLY_OBSCURED; 2 == FULLY_OBSCURED)

    return 3;
}

static int handle_unmap_notify_event(xcb_unmap_notify_event_t *e)
{
    lua_pushstring(xcb_ctx.L, "X_UnmapNotify"); // event_type
    xlhelp_push_id(xcb_ctx.L, e->window); // window_id

    return 2;
}

void event_handle(xcb_generic_event_t *e)
{

    // Strip off the highest bit (set if the event is generated)
    e->response_type &= 0x7F; 

    // this is an error
    if (e->response_type == 0) {
        xutil_xerror_handle((xcb_generic_error_t *) e);
        return;
    }

    switch(e->response_type) {

#define handle_case(match, handler) \
    case match: \
        xlhelp_setup_event_handler(xcb_ctx.L); \
        xlhelp_call_event_handler(xcb_ctx.L, handler((void *)e)); \
        break;

        handle_case(XCB_BUTTON_PRESS, handle_button_event);
        handle_case(XCB_BUTTON_RELEASE, handle_button_event);
        handle_case(XCB_CONFIGURE_NOTIFY, handle_configure_notify_event);
        handle_case(XCB_CREATE_NOTIFY, handle_create_notify_event);
        handle_case(XCB_DESTROY_NOTIFY, handle_destroy_notify_event);
        handle_case(XCB_ENTER_NOTIFY, handle_enter_notify_event);
        handle_case(XCB_EXPOSE, handle_expose_event);
        handle_case(XCB_FOCUS_IN, handle_focus_in_event);
        handle_case(XCB_FOCUS_OUT, handle_focus_out_event);
        // TODO: figure out if I need this anymore
        // handle_case(XCB_GRAPHICS_EXPOSURE, handle_graphics_exposure_event);
        handle_case(XCB_KEY_PRESS, handle_key_event);
        handle_case(XCB_KEY_RELEASE, handle_key_event);
        handle_case(XCB_LEAVE_NOTIFY, handle_leave_notify_event);
        handle_case(XCB_MOTION_NOTIFY, handle_motion_notify_event);
        handle_case(XCB_MAP_NOTIFY, handle_map_notify_event);
        handle_case(XCB_MAP_REQUEST, handle_map_request_event);
        handle_case(XCB_PROPERTY_NOTIFY, handle_property_notify_event);
        handle_case(XCB_REPARENT_NOTIFY, handle_reparent_notify_event);
        handle_case(XCB_VISIBILITY_NOTIFY, handle_visibility_notify_event);
        handle_case(XCB_UNMAP_NOTIFY, handle_unmap_notify_event);
        // // TODO: implement
        // // Mapping notify happens when keyboard mapping changed for example 
        // // when using Xmodmap
        // // - re-allocate keysyms (i think)
        // // - re-grab bindings
        // // case XCB_MAPPING_NOTIFY:
#undef handle_case

    }

    // switch(e->response_type) {
    //
    //     case XCB_BUTTON_PRESS:
    //         nr_args = handle_button_event((xcb_button_press_event_t *)e);
    //         break;
    //     case XCB_BUTTON_RELEASE:
    //         nr_args = handle_button_event((xcb_button_release_event_t *)e);
    //         break;
    //     case XCB_CONFIGURE_NOTIFY:
    //         nr_args = handle_configure_notify((xcb_configure_notify_event_t *)e);
    //         break;
    //     case XCB_CREATE_NOTIFY:
    //         nr_args = handle_create_notify((xcb_create_notify_event_t *)e);
    //         break;
    //     case XCB_DESTROY_NOTIFY:
    //         nr_args = handle_destroy_notify((xcb_destroy_notify_event_t *)e);
    //         break;
    //     case XCB_ENTER_NOTIFY:
    //         nr_args = handle_enter_notify((xcb_enter_notify_event_t *)e);
    //         break;
    //     case XCB_EXPOSE:
    //         nr_args = handle_expose_event((xcb_expose_event_t *)e);
    //         break;
    //     case XCB_FOCUS_IN:
    //         nr_args = handle_focus_in((xcb_focus_in_event_t *)e);
    //         break;
    //     case XCB_FOCUS_OUT:
    //         nr_args = handle_focus_out((xcb_focus_in_event_t *)e);
    //         break;
    //     // TODO: figure out if I need this anymore
    //     // case XCB_GRAPHICS_EXPOSURE:
    //     //     nr_args = handle_graphics_exposure_event((xcb_graphics_exposure_event_t *)e);
    //     //     break;
    //     case XCB_KEY_PRESS:
    //         nr_args = handle_key_event((xcb_key_press_event_t *)e);
    //         break;
    //     case XCB_KEY_RELEASE:
    //         nr_args = handle_key_event((xcb_key_release_event_t *)e);
    //         break;
    //     case XCB_LEAVE_NOTIFY:
    //         nr_args = handle_leave_notify((xcb_leave_notify_event_t *)e);
    //         break;
    //     case XCB_MOTION_NOTIFY:
    //         nr_args = handle_motion_notify((xcb_motion_notify_event_t *)e);
    //         break;
    //     case XCB_MAP_NOTIFY:
    //         nr_args = handle_map_notify((xcb_map_notify_event_t *)e);
    //         break;
    //     case XCB_MAP_REQUEST:
    //         nr_args = handle_map_request((xcb_map_request_event_t *)e);
    //         break;
    //     case XCB_PROPERTY_NOTIFY:
    //         nr_args = handle_property_notify((xcb_property_notify_event_t *)e);
    //         break;
    //     case XCB_REPARENT_NOTIFY:
    //         nr_args = handle_reparent_notify((xcb_reparent_notify_event_t *)e);
    //         break;
    //     case XCB_VISIBILITY_NOTIFY:
    //         nr_args = handle_visibility_notify((xcb_visibility_notify_event_t *)e);
    //         break;
    //     case XCB_UNMAP_NOTIFY:
    //         nr_args = handle_unmap_notify((xcb_unmap_notify_event_t *)e);
    //         break;
    //     default: return
    //
    //     // TODO: implement
    //     // Mapping notify happens when keyboard mapping changed for example 
    //     // when using Xmodmap
    //     // - re-allocate keysyms (i think)
    //     // - re-grab bindings
    //     // case XCB_MAPPING_NOTIFY:
    // }
}


