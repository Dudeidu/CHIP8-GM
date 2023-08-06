if (!surface_exists(surf_display))
{
    surf_display = surface_create(
        CH8_DISPLAY_WIDTH, CH8_DISPLAY_HEIGHT, surface_r8unorm);  
    update_display = true;
}
if (update_display)
{
    //show_debug_message("display update");
    buffer_set_surface(display_buffer, surf_display, 0);
    update_display = false;
}

var _w = CH8_DISPLAY_WIDTH * display_scale;
var _h = CH8_DISPLAY_HEIGHT * display_scale;
var _x = floor(display_get_gui_width() /2 - (_w / 2));
var _y = floor(display_get_gui_height()/2 - (_h / 2));
draw_rectangle(_x-1, _y-1, _x + _w + 1, _y + _h + 1, true);
draw_surface_stretched_ext(surf_display, _x, _y, _w, _h, c_white, 1);