
#define KEY_NAME_BUFFER_LENGTH 64

struct Keybuffer {
    char key_str[KEY_NAME_BUFFER_LENGTH];
};

void terra_xkb_init(void);
void terra_xkb_free(void);

struct Keybuffer terra_xkb_keycode_to_string(xcb_keycode_t keycode);
