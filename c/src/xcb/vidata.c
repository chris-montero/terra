
#include <stdio.h> // for `fprintf`, `stderr`
#include <stdlib.h> // for `exit`

#include <xcb/xcb.h>

#include "sane.h"

#include "xcb/vidata.h"

struct VisualData vidata_find_argb(const xcb_screen_t *s)
{
    struct VisualData vdata;
    vdata.visual = NULL; // used to check for failure
    vdata.visual_depth = 0;

    xcb_depth_iterator_t depth_iter = xcb_screen_allowed_depths_iterator(s);

    if(depth_iter.data == NULL) {
        return vdata;
    }

    while(depth_iter.rem != 0) {

        if (depth_iter.data->depth != 32) {
            printf(
                "Found depth_iterator with depth %d. Skipping.\n", 
                depth_iter.data->depth
            );
            xcb_depth_next(&depth_iter);
            continue;
        }

        printf(
            "Successfully found depth_iterator with depth %d.\n", 
            depth_iter.data->depth
        );

        xcb_visualtype_iterator_t visual_iter = xcb_depth_visuals_iterator(depth_iter.data);
        while (visual_iter.rem != 0) {
            vdata.visual = visual_iter.data;
            vdata.visual_depth = depth_iter.data->depth;
            // TODO: are these any different from each other?
            // printf("Found Visual:\n");
            // printf("\tbits_per_rgb_value: %d\n", visual_iter.data->bits_per_rgb_value);
            // printf("\t_class: %d\n", visual_iter.data->_class);
            // printf("\tcolormap_entries: %d\n", visual_iter.data->colormap_entries);
            // printf("\tred_mask: %d\n", visual_iter.data->red_mask);
            // printf("\tgreen_mask: %d\n", visual_iter.data->green_mask);
            // printf("\tblue_mask: %d\n", visual_iter.data->blue_mask);
            return vdata;
            xcb_visualtype_next(&visual_iter);
        }
    }
    return vdata;
}

struct VisualData vidata_find_default(const xcb_screen_t *s)
{
    struct VisualData vdata;
    vdata.visual = NULL; // used to check for failure
    vdata.visual_depth = 0;

    xcb_depth_iterator_t depth_iter = xcb_screen_allowed_depths_iterator(s);

    if(depth_iter.data == NULL) {
        return vdata;
    }

    printf(
        "Found depth_iterator with depth %d. Using this one as default.\n", 
        depth_iter.data->depth
    );

    xcb_visualtype_iterator_t visual_iter = xcb_depth_visuals_iterator(depth_iter.data);
    while (visual_iter.rem != 0) {
        vdata.visual = visual_iter.data;
        vdata.visual_depth = depth_iter.data->depth;
        // TODO: are these any different from each other?
        // printf("Found Visual:\n");
        // printf("\tbits_per_rgb_value: %d\n", visual_iter.data->bits_per_rgb_value);
        // printf("\t_class: %d\n", visual_iter.data->_class);
        // printf("\tcolormap_entries: %d\n", visual_iter.data->colormap_entries);
        // printf("\tred_mask: %d\n", visual_iter.data->red_mask);
        // printf("\tgreen_mask: %d\n", visual_iter.data->green_mask);
        // printf("\tblue_mask: %d\n", visual_iter.data->blue_mask);
        return vdata;
        xcb_visualtype_next(&visual_iter);
    }

    return vdata;
}

bool vidata_is_invalid(struct VisualData vidata)
{
    if (vidata.visual == NULL) {
        return TRUE;
    } else {
        return FALSE;
    }
}

// u8 vidata_find_visual_depth(const xcb_screen_t *s, xcb_visualid_t vid)
// {
//     xcb_depth_iterator_t depth_iter = xcb_screen_allowed_depths_iterator(s);
//
//     if(!depth_iter.data) { // TODO: check
//         goto abort;
//     }
//     while (depth_iter.rem) { // TODO: check
//         xcb_visualtype_iterator_t visual_iter = xcb_depth_visuals_iterator(depth_iter.data);
//         while (visual_iter.rem) { // TODO: check
//             if(vid == visual_iter.data->visual_id) {
//                 return depth_iter.data->depth;
//             }
//             xcb_visualtype_next(&visual_iter);
//         }
//         xcb_depth_next(&depth_iter);
//     }
//     goto abort; // if everything failed, just close everything
//
// abort:
//     fprintf(stderr, "FATAL: Could not find a visual's depth");
//     exit(1); // TODO: exit with another code once we have all of them figured out?
// }

