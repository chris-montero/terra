
#include <stdio.h> // for `fprintf`, `stderr`
#include <stdlib.h>
#include <execinfo.h> // for backtrace

#include <xcb/xcb.h>
#ifdef DEBUG
#include <xcb/xcb_errors.h>
#endif
#include <X11/Xlib.h> // for `XStringToKeysym()`

#include "app.h"
#include "util.h"

#define MAX_BACKTRACE_STACK_SIZE 32

void util_backtrace_print(void)
{
    void *stack[MAX_BACKTRACE_STACK_SIZE];
    char **symbols;
    int stack_size;

    stack_size = backtrace(stack, NUMBEROF(stack));
    symbols = backtrace_symbols(stack, stack_size);

    if(symbols == NULL) return; // TODO: maybe I can remove this

    fprintf(stderr, "Dumping backtrace:\n");
    for(int i = 0; i < stack_size; i++) {
        fprintf(stderr, "\t%s\n", symbols[i]);
    }
    free(symbols);
}

xcb_keycode_t util_string_to_keycode(const char *str)
{
    xcb_keysym_t keysym = XStringToKeysym(str);
    // TODO: in "/usr/include/xcb/xcb_keysyms.h" it says that this function 
    // can be slow. Maybe we can do it some other way?
    xcb_keycode_t *keycodes = xcb_key_symbols_get_keycode(app.keysyms, keysym); 

    if(keycodes == NULL) return 0;

    // TODO: returning only the first is probably not ok
    xcb_keycode_t keycode = keycodes[0]; 
    free(keycodes); // we are responsible for freeing the keycodes

    return keycode;
}

xcb_keycode_t *util_xcb_keysym_to_keycode(xcb_keysym_t keysym) {
	xcb_keycode_t *keycode = xcb_key_symbols_get_keycode(app.keysyms, keysym); // FIXME: memory leak. this should be freed
	return keycode;
}

xcb_keysym_t util_xcb_keycode_to_keysym(xcb_keycode_t keycode) {
	xcb_keysym_t keysym = xcb_key_symbols_get_keysym(app.keysyms, keycode, 0);
	return keysym;
}

void generic_error_print(xcb_generic_error_t *error)
{
    fprintf(stderr, "XCB ERROR:\n");
    fprintf(stderr, "\terror_code: %d\n", error->error_code);
    fprintf(stderr, "\tsequence: %d\n", error->sequence);
    fprintf(stderr, "\tresource_id: %d\n", error->resource_id);
    fprintf(stderr, "\tminor_code: %d\n", error->minor_code);
    fprintf(stderr, "\tmajor_code: %d\n", error->major_code);
}

#ifdef DEBUG
void util_xerror_handle(xcb_generic_error_t *error)
{
    // ignore this
    // if(e->error_code == XCB_WINDOW
    //    || (e->error_code == XCB_MATCH
    //        && e->major_code == XCB_SET_INPUT_FOCUS)
    //    || (e->error_code == XCB_VALUE
    //        && e->major_code == XCB_KILL_CLIENT)
    //    || (e->error_code == XCB_MATCH
    //        && e->major_code == XCB_CONFIGURE_WINDOW))
    //     return;

    const char *major = xcb_errors_get_name_for_major_code(
        app.xcb_error_ctx, 
        error->major_code
    );
    const char *minor = xcb_errors_get_name_for_minor_code(
        app.xcb_error_ctx,
        error->major_code,
        error->minor_code
    );
    const char *extension = NULL;
    const char *error_str = xcb_errors_get_name_for_error(
        app.xcb_error_ctx,
        error->error_code,
        &extension
    );

    fprintf(stderr, "X error: request - %s%s%s (major %d, minor %d); \terror - (%d) %s%s%s; \tresource_id - (%d)\n",
        major, 
        minor == NULL ? "" : "-", 
        minor == NULL ? "" : minor,
        error->major_code,
        error->minor_code,
        error->error_code,
        extension == NULL ? "" : extension,
        extension == NULL ? "" : "-",
        error_str,
        error->resource_id
    );
}
#endif
