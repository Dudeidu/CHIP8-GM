
if (is_undefined(surf_ui) || !surface_exists(surf_ui)) update_ui = true;

if (update_ui)
{
    update_ui = false;

    var _x = 0;
    var _y = 0;
    var _pad = 5;
    var _str;
    if (!show_help)
    {
        _str =  "[F1] Show prompts";
    }
    else
    {
        var _k = global.interpreter.key_chars;
        _str =
            "[F1] Hide prompts\n\n" +
            "[F2]       Load rom\n" +
            "[F3]       Close rom\n" +
            "[F4]       Pause\n\n" +
            
            "[F5]       Toggle full-screen\n" +
            "[F6][F7]   Change window size\n\n" +
            
            "[F8]       Toggle audio\n\n" +
            
            "[F9][F10]  Change emulator speed\n" +
            "[F11][F12] Change emulator size\n\n" +
            "Key mappings:\n" +
            $"[1][2][3][C]    [{_k[0x1]}][{_k[0x2]}][{_k[0x3]}][{_k[0xC]}]\n" +
            $"[4][5][6][D] -> [{_k[0x4]}][{_k[0x5]}][{_k[0x6]}][{_k[0xD]}]\n" +
            $"[7][8][9][E]    [{_k[0x7]}][{_k[0x8]}][{_k[0x9]}][{_k[0xE]}]\n" +
            $"[A][0][B][F]    [{_k[0xA]}][{_k[0x0]}][{_k[0xB]}][{_k[0xF]}]\n\n";
    }

    draw_set_font(global.font_ui);
    var _w = string_width(_str) + _pad * 2;
    var _h = string_height(_str) + _pad * 2;

    if (is_undefined(surf_ui) || !surface_exists(surf_ui))
    {
        surf_ui = surface_create(_w, _h);
    }
    else
    {
        surface_resize(surf_ui, _w, _h);   
    }

    surface_set_target(surf_ui);
    draw_clear_alpha(c_white, 1);

        draw_set_color(c_black);
        draw_set_alpha(0.5);
        gpu_set_blendmode_ext(bm_one, bm_inv_dest_alpha);
        draw_rectangle(
            _x - _pad, _y - _pad, 
            _x + (_pad*2) + string_width(_str), _y + (_pad*2) + string_height(_str), 
            false);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white);
        draw_set_alpha(1); 

        draw_text(_x + _pad, _y + _pad, _str);
    surface_reset_target();
}


draw_surface(surf_ui, 0, 0);

if (popup_string != "")
{
    draw_set_alpha((popup_timer / 2) * 2);
    var _w = string_width(popup_string);
    var _h = string_height(popup_string);
    draw_text(
        display_get_gui_width()/2 - _w/2, 
        display_get_gui_height()/2 - _h/2, 
        popup_string);
    draw_set_alpha(1);  
}

