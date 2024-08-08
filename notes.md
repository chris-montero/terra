



# TODO
[ ] maybe have separate `set_bounding_geometry`, `set_drawing_geometry`, `get_bounding_geometry` and `get_drawing_geometry` functions, instead of just having `set_geometry` and `get_geometry`. This could be very useful in cases where you want to layer children in a <terra.oak.elements.branches.el> container, you want one of the children to be "anchored" to the relative x & y coordinates of the parent "el", you want this child to draw something, but you don't want it to take up any space in the "el" parent. In this case, you could override the `get_bounding_geometry` and make it `return x, y, 0, 0`. This way, the element would still be allowed to be anchored to the parent and draw, but would not take up any space in the layout.


