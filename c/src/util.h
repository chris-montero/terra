
#include <xcb/xcb.h>

#define UNUSED(x) (void)(x)
#define NUMBEROF(arr) (sizeof((arr)) / sizeof((arr[0])))

#ifdef DEBUG
    // ##__VA_ARGS__ makes it so it removes the last ',' if there's no more args
    #define DLOG(fmt, ...) fprintf(stderr, "%d %s %s : " fmt, __LINE__, __FILE__, __FUNCTION__, ##__VA_ARGS__)
#else
    #define DLOG(...)
#endif

void util_backtrace_print(void);
xcb_keycode_t util_string_to_keycode(const char *str);
xcb_keycode_t *util_xcb_keysym_to_keycode(xcb_keysym_t keysym);
xcb_keysym_t util_xcb_keycode_to_keysym(xcb_keycode_t keycode);

#ifdef DEBUG
void util_xerror_handle(xcb_generic_error_t *error);
#endif
void generic_error_print(xcb_generic_error_t *error);
