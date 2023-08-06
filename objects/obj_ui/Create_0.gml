
// gui
surf_ui = undefined;
show_help = false;

popup_string = "";
popup_timer = 0;

// Program window
draw_offset_x = 0;
draw_offset_y = 0;
window_scale = 2;
full_scale = 1;
fullscreen = false;

window_resize = function(_scale)
{
    window_set_size(WINDOW_WIDTH * _scale, WINDOW_HEIGHT * _scale);
    window_center();   
    surface_resize( application_surface, 
        WINDOW_WIDTH, WINDOW_HEIGHT);
    display_set_gui_maximise(_scale, _scale, 0, 0);   
}

set_fullscreen = function(_full)
{
    var _scale = 1;
    if (_full)
    {
        // Get scale factor depending on screen size
        var _sw = display_get_width();
        var _sh = display_get_height();
        while ((_scale + 1) * WINDOW_WIDTH <= _sw && (_scale + 1) * WINDOW_HEIGHT <= _sh) 
        { 
            _scale ++; 
        }
        full_scale = _scale;
        draw_offset_x = (_sw - (_scale * WINDOW_WIDTH)) / 2;
        draw_offset_y = (_sh - (_scale * WINDOW_HEIGHT)) / 2;
    }
    else
    {
        _scale = window_scale;
        draw_offset_x = 0;
        draw_offset_y = 0;
    }
    window_resize(_scale);
    fullscreen = _full;
    window_set_fullscreen(_full);
}

show_popup = function(_str, _time = 2)
{
    popup_string = _str;
    popup_timer = _time;
}

set_fullscreen(false);
