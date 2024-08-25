
#include <stdlib.h>
#include <string.h> // for `memcpy`

#include <xcb/xkb.h>
#include <xkbcommon/xkbcommon.h>
#include <xkbcommon/xkbcommon-x11.h>

#include "sane.h"

#include "xcb/terra_xkb.h"
#include "xcb/context.h"
#include "xcb/xcb_ctx.h"


// returns true if the given utf-8 string is a control character such as 
// Control or Shift, etc.
bool _is_control_character(char *str)
{
    if (str[0] == (0x7f)/*(127)*/) return TRUE;
    if (str[0] >= 0 && str[0] < 0x20) return TRUE;
    return FALSE;
}

// NOTE: we use this "keybuffer" struct because for some reason we can't just 
// return a simple 64 byte buffer, even though C has ways of specifying how
// large this buffer return value is going to be.
struct Keybuffer terra_xkb_keycode_to_string(xcb_keycode_t keycode)
{
    // XXX: for now, we just use 64 bytes which is usually enough. The output
    // may get truncated, but its a sacrifice I am willing to make.
    // If someone complains, we'll fix this then
    static char str[KEY_NAME_BUFFER_LENGTH]; // xkbcommon/xkbcommon.h recommends a 
    // length of at least 64 bytes, so lets try that.

    // int string_length = xkb_state_key_get_utf8(
    xkb_state_key_get_utf8(
        xcb_ctx.xkb_state,
        keycode,
        str,
        KEY_NAME_BUFFER_LENGTH
    );

    // if the key pressed is a control character, just push the key name, 
    // like "Control", "Shift", etc.
    if (_is_control_character(str)) {
        xcb_keysym_t keysym = xcb_key_symbols_get_keysym(
            xcb_ctx.keysyms,
            keycode,
            0 // col ?? (thats what xcb/xcb_keysyms.h says)
        );
        // the same truncation rules as above apply here. We'll fix it 
        // if we need to
        xkb_keysym_get_name(keysym, str, KEY_NAME_BUFFER_LENGTH);
    }

    struct Keybuffer kbf;
    memcpy(&kbf.key_str, str, KEY_NAME_BUFFER_LENGTH);

    return kbf;
}


// initialize xkb
void terra_xkb_init(void)
{
    // TRUE on success, FALSE on error
    int xkb_success = xkb_x11_setup_xkb_extension( 
        xcb_ctx.connection,
        XKB_X11_MIN_MAJOR_XKB_VERSION,
        XKB_X11_MIN_MINOR_XKB_VERSION,
        0, // extension flags
        NULL, // major_xkb_version_out
        NULL, // minor_xkb_version_out
        NULL, // base_event_out
        NULL // base_error_out
    );

    if (xkb_success == FALSE) {
        fprintf(stderr, "COULDN'T INITIALIZE XKB. EXITING.\n");
        exit(1);
    }

    u16 event_mask = 
        XCB_XKB_EVENT_TYPE_STATE_NOTIFY 
        | XCB_XKB_EVENT_TYPE_MAP_NOTIFY 
        | XCB_XKB_EVENT_TYPE_NEW_KEYBOARD_NOTIFY;

    // maps used to allow key remapping in terra
    u16 remapping_mask = 
        XCB_XKB_MAP_PART_KEY_TYPES 
        | XCB_XKB_MAP_PART_KEY_SYMS 
        | XCB_XKB_MAP_PART_MODIFIER_MAP 
        | XCB_XKB_MAP_PART_EXPLICIT_COMPONENTS 
        | XCB_XKB_MAP_PART_KEY_ACTIONS 
        | XCB_XKB_MAP_PART_KEY_BEHAVIORS 
        | XCB_XKB_MAP_PART_VIRTUAL_MODS 
        | XCB_XKB_MAP_PART_VIRTUAL_MOD_MAP;

    // enable detectable auto-repeat, but ignore failures // TODO: what exactly does this mean
    xcb_xkb_per_client_flags_cookie_t pclient_flags;
    pclient_flags = xcb_xkb_per_client_flags(
        xcb_ctx.connection,
        XCB_XKB_ID_USE_CORE_KBD, // deviceSpec
        XCB_XKB_PER_CLIENT_FLAG_DETECTABLE_AUTO_REPEAT, // change
        XCB_XKB_PER_CLIENT_FLAG_DETECTABLE_AUTO_REPEAT, // value
        0, // ctrlsToChange
        0, // autoCtrls
        0 // autoCtrlsValues
    );
    xcb_discard_reply(
        xcb_ctx.connection,
        pclient_flags.sequence
    );

    xcb_xkb_select_events(
        xcb_ctx.connection,
        XCB_XKB_ID_USE_CORE_KBD, // deviceSpec
        event_mask, // affectWhich
        0, // clear
        event_mask, // selectAll
        remapping_mask, // affectMap
        remapping_mask, // map
        0 // details // TODO: I think this should be NULL
    );

    // Init keymap

    // The steps go as follows: 
    // (1) you create an xkb_context, which you use to 
    // (2) create an xkb_keymap, which you use to 
    // (3) create an xkb_state
    // and finally, in the event handling function, you
    // (4) use the xkb_state in a function like `xkb_state_key_get_utf8` to 
    //      get the string representation of the key pressed or released, etc.
    xcb_ctx.xkb_ctx = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
    if (xcb_ctx.xkb_ctx == NULL) {
        fprintf(stderr, "Could not create XKB context used for resolving keypresses. Exiting.\n");
        exit(1);
    }

    // TODO: learn about xkb concepts like layouts, rules, devices, keymaps, etc. 
    // And xkb in general, and provide lua APIs for working with them

    // try to get id of the current keyboard
    i32 device_id = xkb_x11_get_core_keyboard_device_id(xcb_ctx.connection);
    if (device_id == -1) {
        fprintf(stderr, "Could not get XKB device id. Exiting.");
        exit(1);
    }

    struct xkb_keymap *xkb_keymap = xkb_x11_keymap_new_from_device(
        xcb_ctx.xkb_ctx,
        xcb_ctx.connection,
        device_id,
        XKB_KEYMAP_COMPILE_NO_FLAGS
    );

    if (xkb_keymap == NULL) {
        fprintf(stderr, "Could not get XKB keymap from device. Exiting.");
        exit(1);
    }

    xcb_ctx.xkb_state = xkb_x11_state_new_from_device(
        xkb_keymap,
        xcb_ctx.connection,
        device_id
    );

    // we're done using this keymap, so unref it
    xkb_keymap_unref(xkb_keymap);

    if (xcb_ctx.xkb_state == NULL) {
        fprintf(stderr, "Could not get XKB state from device. Exiting.");
        exit(1);
    }

}


void terra_xkb_free(void)
{
    // unsubscribe from all events
    xcb_xkb_select_events(
        xcb_ctx.connection,
        XCB_XKB_ID_USE_CORE_KBD,
        0,
        0,
        0,
        0,
        0,
        0
    );

    // free keymap related data
    xkb_state_unref(xcb_ctx.xkb_state);
    xkb_context_unref(xcb_ctx.xkb_ctx);
}


