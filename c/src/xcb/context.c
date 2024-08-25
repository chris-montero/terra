
#include <stdlib.h>
#include <locale.h>

#include <lua.h>
#include <lauxlib.h>

#include <xcb/xcb.h>
#include <xcb/xcb_aux.h>
#include <xcb/xcb_event.h>
#ifdef DEBUG
#include <xcb/xcb_errors.h>
#endif

#include "sane.h"
#include "lhelp.h"

#include "xcb/context.h"
#include "xcb/terra_xkb.h"
#include "xcb/vidata.h"
#include "xcb/xlhelp.h"
#include "xcb/event.h"
#include "xcb/xcb_ctx.h"

// static void dummy_xcb_got_event(EV_P_ struct ev_io *io_w, int revents)
// {
//     UNUSED(io_w);
//     UNUSED(revents);
//     // not used because we use "ev_prepare"
// }
//
// static void prepare_cb(EV_P_ struct ev_prepare *prep, int revents)
// {
//     UNUSED(prep);
//     UNUSED(revents);
//
//     xcb_generic_event_t *event1 = NULL;
//     xcb_generic_event_t *event2 = NULL;
//
//     event1 = xcb_poll_for_event(app.connection);
//     while (event1 != NULL) 
//     {
//         // NOTE: it is very common to have a bunch of motion events one after 
//         // the other. It is much more performant to just process the last 
//         // motion event in the queue, and it normally produces the same visual
//         // result anyway. That is why here, in a consecutive list of motion 
//         // events, we only process the last one.
//         event2 = xcb_poll_for_event(app.connection);
//         switch(XCB_EVENT_RESPONSE_TYPE(event1)){
//             case XCB_MOTION_NOTIFY:
//                 // event1 and event2 are both MotionNotify events. 
//                 // If so, continue polling for events until event2 
//                 // is NOT a MotionNotify event.
//                 while (
//                     (event2 != NULL) 
//                     && (XCB_EVENT_RESPONSE_TYPE(event2) == XCB_MOTION_NOTIFY)
//                 ) {
//                     free(event2);
//                     event2 = xcb_poll_for_event(app.connection);
//                 }
//                 break;
//             case XCB_CONFIGURE_NOTIFY:
//                 // the same applies for window resizing events.
//                 while (
//                     (event2 != NULL) 
//                     && (XCB_EVENT_RESPONSE_TYPE(event2) == XCB_CONFIGURE_NOTIFY)
//                 ) {
//                     free(event2);
//                     event2 = xcb_poll_for_event(app.connection);
//                 }
//                 break;
//         }
//
//         event_handle(event1);
//         free(event1);
//
//         event1 = event2;
//     }
//
//     xcb_flush(app.connection);
// }


// static void
// frame_callback(EV_P_ ev_timer *t, int revents) 
// {
//     UNUSED(t);
//     UNUSED(revents);
//
//     // TODO: allow the user to change the frame time in real time
//     app.last_frame_timestamp = ev_now(app.main_loop);
//
//     lhelp_setup_event_handler(app.L);
//
//     // set the type of the event
//     lua_pushstring(app.L, "FrameEvent"); // event_type; TODO: is this a good name?
//     // set the current time
//     // push ev_now() - wm_start so we get seconds since the application started
//     lua_pushnumber(app.L, (double)ev_now(app.main_loop) - app.wm_start); // time
//
//     lhelp_call_event_handler(app.L, 2);
//
//     ev_tstamp present = ev_time();
//     ev_tstamp frame_time = present - app.last_frame_timestamp;
//
//     // printf("Frames: %lu\n", (u64)(1.0d/frame_time));
//
//     // This code instantly fires the callback again if the frame took longer
//     // to draw than it should have, and sleeps if it completed its work faster.
//     // For example: If we want to draw at 144fps, that means we need to
//     // be able to redraw everything in 1/144 seconds, which is about 6ms.
//     // If we take 8ms to draw, this callback is fired again instantly.
//     // If we take 2ms to draw, this callback sleeps for the remaining 4ms.
//     if (frame_time > IDEAL_FRAME_TIME) {
//         // The frame took too long to draw.
//         // Re-call this callback again instantly.
//
//         // TODO: allow the user to create multiple timers
//
//         // NOTE: the libev docs say that this is "the most inefficient way
//         // of doing things" because libev has to completely remove and 
//         // re-insert the timer from/into its internal data structure, which
//         // is not a constant-time operation. 
//         // However, I think this is fine because:
//         // 1. Our application only has one timer, which should mean that in 
//         // our case it IS a constant-time operation. 
//         // 2. We ONLY do this if we took longer to draw the frame than
//         // the ideal time specified by the user.
//         ev_timer_stop(app.main_loop, &app.frame_timer);
//         ev_timer_set(&app.frame_timer, 0.0, 0.0);
//         ev_timer_start(app.main_loop, &app.frame_timer);
//     } else {
//         // the frame finished all work sooner. Sleep until the next frame
//         app.frame_timer.repeat = IDEAL_FRAME_TIME - frame_time;
//         ev_timer_again(app.main_loop, &app.frame_timer);
//     }
// }

// int terra_application_now(lua_State *L)
// {
//     // TODO: It seems that the chronometer is a little faster or slower 
//     // sometimes. Every 7-8 ticks the (current tick - last tick)
//     // is a bit smaller than usual, as measured in lua.
//     // Maybe investigate this if its a problem
//     ev_tstamp t = ev_now(app.main_loop) - app.wm_start;
//     lua_pushnumber(L, (double)t);
//     return 1;
// }

// the only argument to supply to this function is an 
// "event_handler(event_type, ...)" function.
bool xcb_ctx_created = FALSE;
int terra_xcb_context_create(lua_State *L)
{
    xcb_ctx.L = L;
    luaL_checktype(L, 1, LUA_TFUNCTION);

    int status = 0;

    if (xcb_ctx_created == TRUE) {
        // TODO: should we try to let the user start multiple 
        // applications in the same lua vm?
        printf("WARNING: only one xcb context can be started at a time.\n");
        status = 1; exit(status);
    }
    xcb_ctx_created = TRUE;

    // set locale so text prints correctly
    setlocale(LC_ALL, "");

    xcb_ctx.connection = xcb_connect(NULL, &xcb_ctx.default_screen_number);

    status = xcb_connection_has_error(xcb_ctx.connection);
    if (status != 0) {
        // TODO: free everything
        fprintf(stderr, "xcb_connection_has_error: %d.\n", status);
        exit(status);
    }

    // xcb_ctx.main_loop = EV_DEFAULT;
    // if (xcb_ctx.main_loop == NULL) {
    //     // TODO: free everything
    //     fprintf(stderr, "Could not initialize libev.\n");
    //     status = 1;
    //     exit(status);
    // }
    // xcb_ctx.wm_start = ev_now(xcb_ctx.main_loop);

    xcb_ctx.screen = xcb_aux_get_screen(xcb_ctx.connection, xcb_ctx.default_screen_number);
    // xcb_ctx.fallback_visual = vidata_find_default(xcb_ctx.screen);
    struct VisualData vdata = vidata_find_argb(xcb_ctx.screen);
    if (vidata_is_invalid(vdata)) {
        fprintf(stderr, "NO ARGB VISUAL. EXITING.\n");
        status = 1; exit(status);
    }

    xcb_ctx.visual = vdata.visual;
    xcb_ctx.visual_depth = vdata.visual_depth;
    if (xcb_ctx.visual_depth != xcb_ctx.screen->root_depth) {
        // if the visual depth of the root window doesn't match the depth 
        // of the visual we're using, we create our own colormap
        xcb_ctx.default_colormap_id = xcb_generate_id(xcb_ctx.connection);
        xcb_create_colormap(
            xcb_ctx.connection,
            XCB_COLORMAP_ALLOC_NONE,
            xcb_ctx.default_colormap_id,
            xcb_ctx.screen->root,
            xcb_ctx.visual->visual_id
        );
    } else {
        xcb_ctx.default_colormap_id = xcb_ctx.screen->default_colormap;
    }

    // allocate key symbols
    // TODO: this can change if someone plugs in a different keyboard.
    // Implement support for re-allocating this. 
    // Hint: listen for NewKeyboardNotify and MapNotify, as explained in
    // http://xkbcommon.org/doc/current/group__x11.html
	xcb_ctx.keysyms = xcb_key_symbols_alloc(xcb_ctx.connection);

    // init atoms
    // atoms_init(xcb_ctx.connection);
    //
    // terra_ewmh_init();

    // init spawn startup notification
    // startup_notification_init();

    // TODO: DONT FORGET TO FREE THIS WITH `terra_xkb_free`
    terra_xkb_init();


    // this window inherits properties of the root window, which is good for us
    // because we can use this to create a "default" graphics context. This
    // should work for basically any window since you nowdays never need
    // a particular window to have a 4-bit channel for each color or 
    // something highly specific like that.

    xcb_ctx.gc_window = xcb_generate_id(xcb_ctx.connection);
    xcb_ctx.default_gc_id = xcb_generate_id(xcb_ctx.connection);
    // // TODO: can't I just get away with not having this window?
    xcb_create_window(
        xcb_ctx.connection,
        xcb_ctx.visual_depth,
        xcb_ctx.gc_window,
        xcb_ctx.screen->root,
        -1, -1, // x, y
        1, 1, // width, height
        0, // border width
        // TODO: can't this just be "INPUT_ONLY"?
        XCB_WINDOW_CLASS_COPY_FROM_PARENT,
        xcb_ctx.visual->visual_id,
        (u32) 
            XCB_CW_BACK_PIXEL |
            XCB_CW_BORDER_PIXEL |
            XCB_CW_OVERRIDE_REDIRECT |
            XCB_CW_COLORMAP,
        (u32 []) {
            xcb_ctx.screen->black_pixel,
            xcb_ctx.screen->black_pixel,
            1, // override_redirect == TRUE
            xcb_ctx.default_colormap_id
        }
    );

    // window_icccm_set_name(xcb_ctx.connection, xcb_ctx.no_focus_window_id, "terra_gc_window");
    // window_icccm_set_class_name(xcb_ctx.connection, xcb_ctx.no_focus_window_id, TERRA_DEFAULT_CLASS_NAME);
    xcb_map_window(xcb_ctx.connection, xcb_ctx.gc_window);
    xcb_create_gc(
        xcb_ctx.connection,
        xcb_ctx.default_gc_id,
        xcb_ctx.gc_window, // use the "gc_window" as the drawable
        (u32) XCB_GC_FOREGROUND | XCB_GC_BACKGROUND,
        (u32 []) { xcb_ctx.screen->black_pixel, xcb_ctx.screen->white_pixel }
    );
    printf("default gc window id: %d\n", xcb_ctx.gc_window);

    // create cursor context
    if (xcb_cursor_context_new(xcb_ctx.connection, xcb_ctx.screen, &xcb_ctx.cursor_ctx) < 0) {
        fprintf(stderr, "Couldn't initialize xcursor context. Exiting.");
        status = 1; exit(status);
    }

    // set initial cursor
    // TODO: add the ability to change the cursor from lua
    xcb_ctx.current_cursor = xcb_cursor_load_cursor(xcb_ctx.cursor_ctx, "left_ptr"); 
    // xcb_change_window_attributes(
    //     xcb_ctx.connection,
    //     xcb_ctx.screen->root,
    //     XCB_CW_CURSOR,
    //     (u32[]){ xcb_ctx.current_cursor }
    // );

#ifdef DEBUG
    // create error context for the debug build
    if (xcb_errors_context_new(xcb_ctx.connection, &xcb_ctx.xcb_error_ctx) < 0) {
        fprintf(stderr, "Couldn't initialize xcb_errors_context. Exiting.");
        status = 1; exit(status);
    }
#endif
    lua_setfield(L, LUA_REGISTRYINDEX, TERRA_LUA_REGISTRY_EVENT_HANDLER_KEY);

    // return to the caller with a pointer to the xcb context
    lua_pushlightuserdata(L, &xcb_ctx);

    // printf("DUMPING STACK:\n");
    // lhelp_dump_stack(L);

    // int error = lhelp_start_xcb_ctx(L);
    // if (error != 0) {
    //     // TODO: free everything
    //     fprintf(stderr, "%s\n", lua_tostring(L, -1));
    //     lua_pop(L, -1); // pop error message
    //     status = 1; exit(status);
    // }

    // xcb_window_t test_win = xcb_generate_id(xcb_ctx.connection);

    // printf("MAKING WINDOW WITH:\n");
    // printf("\twindow id: %d\n", test_win);
    // printf("\tvisual id: %d\n", xcb_ctx.visual->visual_id);
    // printf("\tvisual depth: %d\n", xcb_ctx.visual_depth);
    // printf("\tparent id: %d\n", xcb_ctx.screen->root);
    // printf("\tcolormap id: %d\n", xcb_ctx.default_colormap_id);
    // xcb_void_cookie_t v = xcb_create_window_checked(
    //     xcb_ctx.connection,
    //     xcb_ctx.visual_depth,
    //     test_win,
    //     xcb_ctx.screen->root,
    //     50, 50, // x, y
    //     100, 100, // width, height
    //     0, // border width
    //     // TODO: can't this just be "INPUT_ONLY"?
    //     XCB_WINDOW_CLASS_COPY_FROM_PARENT,
    //     xcb_ctx.visual->visual_id,
    //     (u32) 
    //         XCB_CW_BACK_PIXEL |
    //         XCB_CW_BORDER_PIXEL |
    //         XCB_CW_OVERRIDE_REDIRECT |
    //         XCB_CW_COLORMAP,
    //     (u32 []) {
    //         xcb_ctx.screen->black_pixel,
    //         xcb_ctx.screen->black_pixel,
    //         1, // override_redirect == TRUE
    //         xcb_ctx.default_colormap_id
    //     }
    // );
    //
    // xcb_generic_error_t *err = xcb_request_check(xcb_ctx.connection, v);
    // if (err == NULL) {
    //     printf("NO ERROR FOR WINDOW %d\n", test_win);
    // } else {
    //     printf("ERROR FOR WINDOW %d\n", test_win);
    //     event_handle((xcb_generic_event_t *) err);
    //     free(err);
    // }
    // xcb_map_window(xcb_ctx.connection, test_win);

    // xcb_change_window_attributes(
    //     xcb_ctx.connection,
    //     xcb_ctx.screen->root,
    //     XCB_CW_EVENT_MASK,
    //     (u32[]){
    //         XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY
    //         | XCB_EVENT_MASK_PROPERTY_CHANGE
    //         // | XCB_EVENT_MASK_FOCUS_CHANGE
    //     }
    // );

    // lhelp_dump_stack(L);

    // printf("screen depth: %d\n", xcb_ctx.screen->root_depth);

    // struct ev_io *io_watcher = malloc(sizeof(struct ev_io));
    // struct ev_prepare *prepare_watcher = malloc(sizeof(struct ev_prepare));

    // ev_prepare_init(prepare_watcher, prepare_cb);
    // ev_prepare_start(xcb_ctx.main_loop, prepare_watcher);
    //
    // ev_io_init(io_watcher, dummy_xcb_got_event, xcb_get_file_descriptor(xcb_ctx.connection), EV_READ);
    // ev_io_start(xcb_ctx.main_loop, io_watcher);

    // xcb_ctx.last_frame_timestamp = ev_now(xcb_ctx.main_loop);

    // ev_timer_init(&xcb_ctx.frame_timer, frame_callback, 0, 0);
    // ev_timer_start(xcb_ctx.main_loop, &xcb_ctx.frame_timer);

    // ev_loop(xcb_ctx.main_loop, 0);

    return 1;
}

int terra_xcb_context_destroy(lua_State *L)
{
	xcb_key_symbols_free(xcb_ctx.keysyms);
    xcb_cursor_context_free(xcb_ctx.cursor_ctx);
    terra_xkb_free(); // TODO: parameterize this
    // should the user be able to start multiple apps from the same lua VM?

#ifdef DEBUG
    xcb_errors_context_free(xcb_ctx.xcb_error_ctx);
#endif

    xcb_disconnect(xcb_ctx.connection);
    return 0;
}

int terra_xcb_context_flush(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    xcb_flush(xc->connection);
    return 0;
}

int terra_xcb_context_sync(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    xcb_aux_sync(xc->connection);
    return 0;
}

int terra_xcb_context_get_file_descriptor(lua_State *L)
{
    struct XcbContext *xc = xlhelp_check_xcb_ctx(L, 1);
    lua_pushinteger(L, xcb_get_file_descriptor(xc->connection));
    return 1;
}

int terra_xcb_context_handle_events(lua_State *L)
{
    xcb_generic_event_t *event1 = NULL;
    xcb_generic_event_t *event2 = NULL;

    event1 = xcb_poll_for_event(xcb_ctx.connection);
    while (event1 != NULL)
    {
        // NOTE: it is very common to have a bunch of motion events one after 
        // the other. It is much more performant to just process the last 
        // motion event in the queue, and it normally produces the same visual
        // result anyway. That is why here, in a consecutive list of motion 
        // events, we only process the last one.
        // the same applies for window resizing events (CONFIGURE_NOTIFY).
        event2 = xcb_poll_for_event(xcb_ctx.connection);
        switch(XCB_EVENT_RESPONSE_TYPE(event1)){
            case XCB_MOTION_NOTIFY:
                // event1 and event2 are both MotionNotify events.
                // If so, continue polling for events until event2 
                // is NOT a MotionNotify event.
                while (
                    (event2 != NULL)
                    && (XCB_EVENT_RESPONSE_TYPE(event2) == XCB_MOTION_NOTIFY)
                ) {
                    free(event2);
                    event2 = xcb_poll_for_event(xcb_ctx.connection);
                }
                break;
            case XCB_CONFIGURE_NOTIFY:
                while (
                    (event2 != NULL)
                    && (XCB_EVENT_RESPONSE_TYPE(event2) == XCB_CONFIGURE_NOTIFY)
                ) {
                    free(event2);
                    event2 = xcb_poll_for_event(xcb_ctx.connection);
                }
                break;
        }

        event_handle(event1);
        free(event1);

        event1 = event2;
    }

    xcb_flush(xcb_ctx.connection);
    return 0;
}

static const struct luaL_Reg lib_terra_xcb_ctx[] = {
    { "create", terra_xcb_context_create },
    { "destroy", terra_xcb_context_destroy },
    { "get_file_descriptor", terra_xcb_context_get_file_descriptor },
    { "handle_events", terra_xcb_context_handle_events },

// TODO: determine if I even need these anymore
    { "flush", terra_xcb_context_flush },
    { "sync", terra_xcb_context_sync},
    { NULL, NULL },
};

int luaopen_terra_platforms_xcb_ctx(lua_State *L)
{
    luaL_newlib(L, lib_terra_xcb_ctx);

    return 1;
}

