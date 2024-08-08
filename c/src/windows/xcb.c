
// #include <stdlib.h> // for `free` // TODO: remove
#include <stdio.h> // for `printf` TODO: remove

#include <xcb/xcb.h>

#include "application.h"


xcb_window_t terra_window_xcb_create(struct Application *ap, i16 x, i16 y, u16 width, u16 height, u8 override_redirect)
{
    // lhelp_dump_stack(L);

    xcb_event_mask_t ev_mask = 
        XCB_EVENT_MASK_KEY_PRESS
        | XCB_EVENT_MASK_KEY_RELEASE
        | XCB_EVENT_MASK_BUTTON_PRESS
        | XCB_EVENT_MASK_BUTTON_RELEASE
        | XCB_EVENT_MASK_ENTER_WINDOW
        | XCB_EVENT_MASK_LEAVE_WINDOW
        | XCB_EVENT_MASK_POINTER_MOTION
        | XCB_EVENT_MASK_EXPOSURE
        | XCB_EVENT_MASK_VISIBILITY_CHANGE
        | XCB_EVENT_MASK_STRUCTURE_NOTIFY
        | XCB_EVENT_MASK_FOCUS_CHANGE
        | XCB_EVENT_MASK_PROPERTY_CHANGE;

        // | XCB_EVENT_MASK_KEYMAP_STATE
        // | XCB_EVENT_MASK_RESIZE_REDIRECT
        // | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY
        // | XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT
        // | XCB_EVENT_MASK_COLOR_MAP_CHANGE
        // | XCB_EVENT_MASK_OWNER_GRAB_BUTTON

    xcb_window_t x_window_id = xcb_generate_id(ap->connection);

    // NOTE: apparently we MUST specify values for BACK_PIXEL and 
    // BORDER_PIXEL, otherwise the window doesn't show up? I don't know why.
    u32 x_window_value_mask =
        XCB_CW_BACK_PIXEL
        | XCB_CW_BORDER_PIXEL
        | XCB_CW_BIT_GRAVITY
        | XCB_CW_OVERRIDE_REDIRECT
        | XCB_CW_EVENT_MASK
        | XCB_CW_COLORMAP;
        // XCB_CW_CURSOR; // TODO: select cursor
    u32 x_window_value_list[] = {
        ap->screen->black_pixel,
        ap->screen->black_pixel,
        XCB_GRAVITY_NORTH_WEST,
        override_redirect,
        ev_mask,
        ap->default_colormap_id
    };
    xcb_create_window(
        ap->connection,
        ap->visual_depth,
        x_window_id,
        ap->screen->root, // parent id
        x,
        y,
        width,
        height,
        0, // border width (the window manager will take care of this)
        XCB_WINDOW_CLASS_INPUT_OUTPUT,
        // XCB_WINDOW_CLASS_COPY_FROM_PARENT,
        ap->visual->visual_id, // TODO: learn more about visuals
        x_window_value_mask,
        x_window_value_list
    );

    return x_window_id;
}

void terra_window_xcb_change_cursor(struct Application *ap, xcb_window_t x_window_id, char *cursor_str)
{
    xcb_cursor_t new_cursor = xcb_cursor_load_cursor(ap->cursor_ctx, cursor_str);
    xcb_cursor_t old_cursor = ap->current_cursor;
    xcb_change_window_attributes(
        ap->connection,
        x_window_id,
        XCB_CW_CURSOR,
        (u32[]){ new_cursor }
    );
    xcb_free_cursor(ap->connection, old_cursor);
    ap->current_cursor = new_cursor;
}

void terra_window_xcb_set_geometry_request(
    struct Application *ap,
    xcb_window_t x_window_id,
    i16 x,
    i16 y,
    u16 width,
    u16 height
) {
    u32 window_config_mask = 
        XCB_CONFIG_WINDOW_X 
        | XCB_CONFIG_WINDOW_Y
        | XCB_CONFIG_WINDOW_WIDTH
        | XCB_CONFIG_WINDOW_HEIGHT;

    const i32 window_config_values[] = { x, y, width, height };

    xcb_configure_window(
        ap->connection,
        x_window_id,
        window_config_mask,
        window_config_values
    );
    // xcb_flush(ap->connection);
}

void terra_window_xcb_set_sizes_request(struct Application *ap, xcb_window_t x_window_id, u16 width, u16 height)
{
    u32 client_config_mask = XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT;
    const u32 client_config_values[] = { width, height };
    xcb_configure_window(
        ap->connection,
        x_window_id,
        client_config_mask,
        client_config_values
    );
}

void terra_window_xcb_set_coordinates_request(struct Application *ap, xcb_window_t x_window_id, i16 x, i16 y)
{
    u32 client_config_mask = XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y;
    const u32 client_config_values[] = { x, y };

    xcb_configure_window(
        ap->connection,
        x_window_id,
        client_config_mask,
        client_config_values
    );
}


// void terra_window_xcb_map_request(struct Application *ap, xcb_window_t x_window_id)
// {
//     xcb_map_request_event_t mr;
//
//     mr.response_type = XCB_MAP_REQUEST;
//     mr.parent = ap->screen->root;
//     mr.window = x_window_id;
//     xcb_send_event(
//         ap->connection, 
//         FALSE, // override_redirect
//         ap->screen->root,
//         XCB_EVENT_MASK_STRUCTURE_NOTIFY, 
//         (char *) &mr
//     );
//     // xcb_flush(ap->connection);
// }

void terra_window_xcb_map_request(struct Application *ap, xcb_window_t x_window_id)
{
    xcb_map_window(ap->connection, x_window_id);
}

void terra_window_xcb_unmap(struct Application *ap, xcb_window_t x_window_id)
{
    xcb_unmap_window(ap->connection, x_window_id);
}

void terra_window_xcb_destroy(struct Application *ap, xcb_window_t x_window_id)
{
    xcb_destroy_window(ap->connection, x_window_id);
}

// // TODO: make this work based on properties
// void terra_window_xcb_set_focus_request(struct Application *ap, xcb_window_t window_id) {
//     if (window_id == XCB_NONE) return;
//     xcb_set_input_focus(
//         ap->connection,
//         XCB_INPUT_FOCUS_POINTER_ROOT,
//         // XCB_INPUT_FOCUS_NONE,
//         window_id,
//         XCB_CURRENT_TIME
//     );
// }


// // TODO: maybe I should just let users only rely on automatic grabs?
// void terra_window_xcb_grab_pointer(xcb_window_t x_win_id, xcb_event_mask_t event_mask)
// {
//     xcb_grab_pointer(
//         ap->connection,
//         FALSE, // "owner_events" (if the grab window should still get the events)
//         x_win_id,
//         event_mask,
//         XCB_GRAB_MODE_ASYNC,
//         XCB_GRAB_MODE_ASYNC,
//         XCB_NONE, // confine_to
//         XCB_NONE, // cursor
//         XCB_CURRENT_TIME
//     );
// }
// void terra_window_xcb_ungrab_pointer()
// {
//     xcb_ungrab_pointer(ap->connection, XCB_CURRENT_TIME);
// }
//

// void terra_window_xcb_subscribe_key(xcb_window_t x_win_id, struct Key key)
// {
//     // xcb_keycode_t *keycode = util_xcb_keysym_to_keycode(keybindings[i].keysym); // TODO: dont I have to free this??
//     xcb_grab_key(
//         ap->connection,
//         FALSE, // owner_events. Should the window still get the event for this key?
//         x_win_id,
//         key.modifiers,
//         key.keycode,
//         XCB_GRAB_MODE_ASYNC,
//         XCB_GRAB_MODE_ASYNC 
//     );
// }
//
// void terra_window_xcb_unsubscribe_key(xcb_window_t x_win_id, struct Key key)
// {
//     xcb_ungrab_key(
//         ap->connection,
//         key.keycode,
//         x_win_id,
//         key.modifiers
//     );
// }
//
// void terra_window_xcb_subscribe_click(xcb_window_t x_win_id, struct Click click)
// {
//     xcb_grab_button(
//         ap->connection,
//         TRUE, // owner events. should the grabbing window still get events?
//         x_win_id,
//         XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
//         XCB_GRAB_MODE_ASYNC,
//         XCB_GRAB_MODE_ASYNC,
//         ap->screen->root, // confine_to window
//         // x_win_id,
//         XCB_NONE, // cursor
//         click.button,
//         click.modifiers
//     );
// }
//
// void terra_window_xcb_unsubscribe_click(xcb_window_t x_win_id, struct Click click)
// {
//     xcb_ungrab_button(
//         ap->connection,
//         click.button,
//         x_win_id,
//         click.modifiers
//     );
// }

