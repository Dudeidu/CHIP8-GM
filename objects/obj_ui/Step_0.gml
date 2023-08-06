
if (popup_timer > 0)
{
    popup_timer -= min(0.1667, delta_time / 1000000);
    if (popup_timer <= 0) popup_string = "";
}


// Expand ui prompts
if (keyboard_check_pressed(vk_f1))
{
    show_help = !show_help; 
    update_ui = true;
}

// Load rom
if (keyboard_check_pressed(vk_f2))
{
    with(global.interpreter)
    {
        ch8_initialize();
        var _fname = get_open_filename("chip-8 program|*.ch8", "");
        if (_fname != "")
        {
            load_program(_fname);
            other.show_popup($"Loaded rom: {_fname}");
        }
        else
        {
            other.show_popup("Rom loading failed");
        }
    }
}

// Reset the interpreter
if (keyboard_check_pressed(vk_f3))
{
    if (global.interpreter.interpreter_running)
    {
        global.interpreter.ch8_initialize();
        show_popup("Reset");
    }
}

// Pause the interpreter
if (keyboard_check_pressed(vk_f4))
{
    with(global.interpreter)
    {
        if (interpreter_running) 
        {
            paused = !paused;
            other.show_popup(paused ? "Pause" : "Play");
        }
    }
}

// Toggle fullscreen
if (keyboard_check_pressed(vk_f5))
{
    set_fullscreen(!fullscreen);
    show_popup(fullscreen ? "Fullscreen" : "Windowed");
}

// Window resize
if (keyboard_check_pressed(vk_f6))
{
    if (!fullscreen)
    {
        var _scale_prev = window_scale;
        window_scale = max(1, window_scale - 1);
        if (_scale_prev != window_scale)
        {
            window_resize(window_scale); 
            show_popup($"Window scale: {window_scale}x");
        }
    }
}
if (keyboard_check_pressed(vk_f7))
{
    if (!fullscreen)
    {
        var _scale_prev = window_scale;
        window_scale = min(window_scale + 1, display_get_width() div WINDOW_WIDTH);
        if (_scale_prev != window_scale)
        {
            window_resize(window_scale); 
            show_popup($"Window scale: {window_scale}x");
        }
    }
}

// Toggle audio
if (keyboard_check_pressed(vk_f8))
{
    with(global.interpreter)
    {
        muted = !muted;
        other.show_popup(muted ? "Audio OFF" : "Audio ON");
    }
}

// Emulator speed
if (keyboard_check_pressed(vk_f9))
{
    with(global.interpreter)
    {
        tick_rate_modifier = max(0.25, tick_rate_modifier / 2);
        other.show_popup($"Emulator speed: {tick_rate_modifier}x");
    }
}
if (keyboard_check_pressed(vk_f10))
{
    with(global.interpreter)
    {
        tick_rate_modifier = min(tick_rate_modifier * 2, 8);
        other.show_popup($"Emulator speed: {tick_rate_modifier}x");
    }
}

// Emulator size
if (keyboard_check_pressed(vk_f11))
{
    with(global.display)
    {
        display_scale = max(1, display_scale - 1);
        other.show_popup($"Emulator size: {display_scale}x");
    }
}
if (keyboard_check_pressed(vk_f12))
{
    with(global.display)
    {
        display_scale = min(5, display_scale + 1);
        other.show_popup($"Emulator size: {display_scale}x");
    }
}