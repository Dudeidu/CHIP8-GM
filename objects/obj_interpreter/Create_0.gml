///@description 

#region CHIP-8 data structures

registers = {
    v :     array_create(16),   // General purpose for 8-bit values
    index : 0x0,                // General purpose for storing addresses (16-bit)
    pc :    CH8_ADDR_PROG,      // Stores the offset of the next instruction
    sp :    CH8_ADDR_STACK,     // Stores the current position of the stack
    stack:  array_create(16),   // Stack of 16-bit addresses
    dt :    0,                  // delay timer
    st :    0,                  // sound timer
    rpl:    array_create(8)     // (superchip only) stores 8-bit values
}

memory_buffer = buffer_create(CH8_MEMORY_MAX, buffer_fast, 1);
program_offset = 0; // Programs are loaded into memory at 0x200, you can specify additional offset
interpreter_running = false;
paused = false;
muted = false;

dt = 0;
start_timer = 0;
running_time = 0;
last_delay_time = 0;
last_sound_time = 0;
tick_rate = 1/600 ; // How often to run instructions (limited by the actual cpu)
tick_rate_modifier = 1;

#endregion

#region Debugging

ch8_debug_mode = false;
instruction_current = 0;

hex_to_string = function(_hex, _digits)
{
    var _str = _hex == 0 ? string_format(_hex, _digits, 0) : string(ptr(_hex));
    return string_copy(_str, string_length(_str) - (_digits - 1), _digits);     
}
ch8_debug_message = function(_str)
{
    var _ins = hex_to_string(instruction_current, 4);
    var _pc = hex_to_string(registers.pc, 4);
    show_debug_message($"[{_pc}] [{_ins}]: {_str}");
}

#endregion

#region Graphics

high_resolution = false;

font_set = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    // High resolution font
    0x3C, 0x7E, 0xE7, 0xC3, 0xC3, 0xC3, 0xC3, 0xE7, 0x7E, 0x3C, // 0
    0x18, 0x38, 0x58, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, // 1
    0x3E, 0x7F, 0xC3, 0x06, 0x0C, 0x18, 0x30, 0x60, 0xFF, 0xFF, // 2
    0x3C, 0x7E, 0xC3, 0x03, 0x0E, 0x0E, 0x03, 0xC3, 0x7E, 0x3C, // 3
    0x06, 0x0E, 0x1E, 0x36, 0x66, 0xC6, 0xFF, 0xFF, 0x06, 0x06, // 4
    0xFF, 0xFF, 0xC0, 0xC0, 0xFC, 0xFE, 0x03, 0xC3, 0x7E, 0x3C, // 5
    0x3E, 0x7C, 0xC0, 0xC0, 0xFC, 0xFE, 0xC3, 0xC3, 0x7E, 0x3C, // 6
    0xFF, 0xFF, 0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x60, 0x60, // 7
    0x3C, 0x7E, 0xC3, 0xC3, 0x7E, 0x7E, 0xC3, 0xC3, 0x7E, 0x3C, // 8
    0x3C, 0x7E, 0xC3, 0xC3, 0x7F, 0x3F, 0x03, 0x03, 0x3E, 0x7C  // 9
];


#endregion

#region Sound

sound_tone = snd_chip8_tone;

#endregion

#region Virtual keyboard
/*
    1 2 3 C  -> 1 2 3 4
    4 5 6 D     q w e r
    7 8 9 E     a s d f
    A 0 B F     z x c v
*/
lut_virtual_keys = lut_create([
    [0x0, ord("X")],
    [0x1, ord("1")],
    [0x2, ord("2")],
    [0x3, ord("3")],
    [0x4, ord("Q")],
    [0x5, ord("W")],
    [0x6, ord("E")],
    [0x7, ord("A")],
    [0x8, ord("S")],
    [0x9, ord("D")],
    [0xA, ord("Z")],
    [0xB, ord("C")],
    [0xC, ord("4")],
    [0xD, ord("R")],
    [0xE, ord("F")],
    [0xF, ord("V")]
]);

// Get key character list
key_chars = array_create(16);
for (var i=0; i<16; i++)
{
    key_chars[@ i] = chr(lut_virtual_keys[? i]);
}

key_press_checked = false;
waiting_for_key_press = -1; // when >= 0, pause execution until a key is pressed
                            // Then, store the pressed key number to the Vx with the index of this variable

#endregion

#region Instructions (CHIP-8)

ext_system = function(_ins)
{
    if (_ins >> 4 == 0xC)
        scroll_down(_ins);
    else
    {
        // Search for the instruction in the lookup table and call the method, passing along the instruction
        try
        {
            lut_system[? _ins](_ins);
        }
        catch(_exception)
        {
            var _str = string(ptr(_ins));
            var _ins_hex = string_copy(_str, string_length(_str) - 3, 4); 
            show_message($"Instruction error: {_ins_hex}");
            global.ui.show_popup("Program terminated due to error"); 
            interpreter_running = false;
        }
    }
}

ext_var = function(_ins)
{
    var _vx = _ins >> 8; // Extract the leftmost digit
    var _vy = (_ins >> 4) & 0xF; // Extract the middle digit
    _ins = _ins & 0xF; // Extract the rightmost digit
    // Search for the instruction in the lookup table and call the method, passing along the variable numbers
    try
    {
        lut_var[? _ins](_vx, _vy);
    }
    catch(_exception)
    {
        var _str = string(ptr(_ins));
        var _ins_hex = string_copy(_str, string_length(_str) - 3, 4); 
        show_message($"Instruction error: {_ins_hex}");
        global.ui.show_popup("Program terminated due to error"); 
        interpreter_running = false;
    }
}

ext_keyboard = function(_ins)
{
    var _vx = _ins >> 8; // Extract the leftmost digit
    _ins = _ins & 0xFF; // Extract the 2 rightmost digits
    // Search for the instruction in the lookup table and call the method, passing along the variable numbers
    try
    {
        lut_keyboard[? _ins](_vx);
    }
    catch(_exception)
    {
        var _str = string(ptr(_ins));
        var _ins_hex = string_copy(_str, string_length(_str) - 3, 4); 
        show_message($"Instruction error: {_ins_hex}");
        global.ui.show_popup("Program terminated due to error"); 
        interpreter_running = false;
    }
}

ext_misc = function(_ins)
{
    var _vx = _ins >> 8; // Extract the leftmost digit
    _ins = _ins & 0xFF; // Extract the 2 rightmost digits
    // Search for the instruction in the lookup table and call the method, passing along the variable numbers
    try
    {
        lut_misc[? _ins](_vx);
    }
    catch(_exception)
    {
        var _str = string(ptr(_ins));
        var _ins_hex = string_copy(_str, string_length(_str) - 3, 4); 
        show_message($"Instruction error: {_ins_hex}");
        global.ui.show_popup("Program terminated due to error"); 
        interpreter_running = false;
    }
}

clear_display = function(_ins)
{
    // Clear display buffer with 0 values, then set flag for display to redraw itself.
    var _display_buffer = global.display.display_buffer;
    var _buffer_size = buffer_get_size(_display_buffer);
    buffer_fill(_display_buffer, 0, buffer_u8, 0, _buffer_size);
    global.display.update_display = true; 
}

return_from_subroutine = function(_ins)
{
    var _stack_pointer = registers.sp;
    // Sets the program counter to the address at the top of the stack
    registers.pc = registers.stack[_stack_pointer];
    // Subtracts from the stack pointer
    registers.sp = (_stack_pointer - 1) & 0xF;  
}

jump_to_address = function(_ins)
{
    // Jump to location nnn.
    // Sets the program counter to nnn.
    registers.pc = _ins;   
}

call_subroutine = function(_ins)
{
    // Increments the stack pointer
    registers.sp = (registers.sp + 1) & 0xF;  
    // Puts the current PC on the top of the stack.
    registers.stack[@ registers.sp] = registers.pc;
    // Set PC to nnn
    registers.pc = _ins;
}

skip_if_var_equal_val = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _value = _ins & 0xFF; // 2 rightmost digits
    if (registers.v[_vx] == _value)
        registers.pc += 2;
}

skip_if_var_not_equal_val = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _value = _ins & 0xFF; // 2 rightmost digits
    if (registers.v[_vx] != _value) 
        registers.pc += 2;
}

skip_if_var_equal_var2 = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _vy = (_ins >> 4) & 0xF; // middle digit
    if (registers.v[_vx] == registers.v[_vy])
        registers.pc += 2;
}

set_var_to_val = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _value = _ins & 0xFF; // 2 rightmost digits
    registers.v[@ _vx] = _value;
}

add_val_to_var = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _value = _ins & 0xFF; // 2 rightmost digits
    registers.v[@ _vx] = (registers.v[@ _vx] + _value) & 0xFF;
}

set_var_to_var2 = function(_vx, _vy)
{
    registers.v[@ _vx] = registers.v[ _vy];
}

set_var_to_var_or_var2 = function(_vx, _vy)
{
    registers.v[@ _vx] = registers.v[_vx] | registers.v[ _vy];
}

set_var_to_var_and_var2 = function(_vx, _vy)
{
    registers.v[@ _vx] = registers.v[_vx] & registers.v[ _vy];
}

set_var_to_var_xor_var2 = function(_vx, _vy)
{
    registers.v[@ _vx] = registers.v[_vx] ^ registers.v[ _vy];
}

add_var2_to_var = function(_vx, _vy)
{
    // The values of Vx and Vy are added together.
    var _sum = (registers.v[_vx] + registers.v[ _vy]);
    // If the result is greater than 8 bits, VF is set to 1, otherwise 0.
    registers.v[@ 0xF] = _sum > 0xFF;
    // Only the lower 8 bits are stored to Vx (simulate 8-bit interger overflow)
    registers.v[@ _vx] = _sum & 0xFF;
}

subtract_var2_from_var = function(_vx, _vy)
{
    var _diff = (registers.v[_vx] - registers.v[_vy]);
    // If Vx >= Vy, then VF is set to 1, otherwise 0
    registers.v[@ 0xF] = _diff >= 0;
    // Store the result in Vx (simulate 8-bit interger overflow)
    registers.v[@ _vx] = _diff & 0xFF;
}

shift_right_var = function(_vx, _vy)
{
    var _x = registers.v[_vx];
    // If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0.
    registers.v[@ 0xF] = _x & 1;
    // right bit-shift Vx (divide by 2)
    registers.v[@ _vx] = _x >> 1;
}

subtract_var_from_var2 = function(_vx, _vy)
{
    // Vx is subtracted from Vy
    var _diff = (registers.v[_vy] - registers.v[_vx]);
    // If Vy >= Vx, then VF is set to 1, otherwise 0
    registers.v[@ 0xF] = (_diff >= 0) ? 1 : 0;
    // Store the results stored in Vx (simulate 8-bit interger overflow)
    registers.v[@ _vx] = _diff & 0xFF;
}

shift_left_var = function(_vx, _vy)
{
    var _x = registers.v[@ _vx];
    // If the most-significant bit of Vx is 1, then VF is set to 1, otherwise 0.
    registers.v[@ 0xF] = _x >> 7;
    // left bit-shift Vx (multiply by 2)
    registers.v[@ _vx] = (_x << 1) & 0xFF;
}

skip_if_var_not_equal_var2 = function(_ins)
{
    var _vx = _ins >> 8; // leftmost digit
    var _vy = (_ins >> 4) & 0xF; // middle digit
    if (registers.v[_vx] != registers.v[_vy])
        registers.pc += 2;
}

set_index_to_address = function(_ins)
{
    registers.index = _ins;
}

jump_to_address_plus_val = function(_ins)
{
    // The program counter is set to nnn plus the value of V0.
    registers.pc = _ins + registers.v[0];
}

set_var_to_random = function(_ins)
{
    // Generate a random 8-bit number.
    var _rnd = irandom(0xFF);
    // bitmask the random number by value, and store the result in Vx (Similar to modulo)
    var _value = _ins & 0xFF; // 2 rightmost digits
    _rnd = _rnd & _value;
    
    var _vx = _ins >> 8; // leftmost digit
    registers.v[_vx] = _rnd;
}

ch8_draw_sprite = function(_ins)
{
    // Display n-byte sprite starting at memory location I at (Vx, Vy)
    // In high resolution mode, display 16x16 bytes instead.
    var _n = _ins & 0xF; // rightmost digit
    if (_n == 0 && !high_resolution) return;

    var _xs = registers.v[_ins >> 8];           // leftmost digit
    var _ys = registers.v[(_ins >> 4) & 0xF];   // middle digit
    
    if (_n == 0) ch8_draw_sprite_high_res(_xs, _ys);
    else ch8_draw_sprite_low_res(_xs, _ys, _n);
}

ch8_draw_sprite_low_res = function(_xs, _ys, _n)
{
    // Even at low resolution mode, the display size is still 128x64.
    // each pixel is drawn as a 2x2 pixel to be compatible with the SUPERCHIP's higher resolution. 
    var _highres = high_resolution;
    if (!_highres)
    {
        _xs = _xs << 1;
        _ys = _ys << 1;
    }
    
    var _buffer = memory_buffer;
    var _display_buffer = global.display.display_buffer;
    
    var _index = registers.index;
    var _collisions = 0;
    
    for (var _y=0; _y<_n; _y++) // row of 8 pixels
    {
        if (_index + _y >= CH8_MEMORY_MAX) break;
        
        var _collision = false;
        // Get the sprite: read n bytes from memory, starting at the address stored in I.
        var _byte = buffer_peek(_buffer, _index + _y, buffer_u8);
        var _y_off = _highres ? _y : _y << 1;
        // Loop through each bit and set the corresponding byte in the buffer
        var _bit_pos = 7; // reverse the bit order
        for (var _x=0; _x<8; _x++) 
        {
            var _x_off = _highres ? _x : _x << 1;
            // Sprite wraps around the screen
            var _buffer_offset = ((_xs + _x_off) % CH8_DISPLAY_WIDTH) + (((_ys + _y_off) % CH8_DISPLAY_HEIGHT) * CH8_DISPLAY_WIDTH);
            
            // Sprites are XORred with existing pixels on the display
            var _old_pixel = buffer_peek(_display_buffer, _buffer_offset, buffer_u8);
            var _new_pixel = (((_byte >> _bit_pos) & 1) * 255) ^ _old_pixel;
            
            // If pixel was deleted
            if (!_collision && ((_old_pixel != 0 && _new_pixel == 0) || (_highres && _ys + _y >= CH8_DISPLAY_HEIGHT)))
                _collision = true;
                
            // Write new color to display buffer as a 2x2 pixel
            if (!_highres)
            {
                buffer_fill(_display_buffer, _buffer_offset, buffer_u8, _new_pixel, 2);
                buffer_fill(_display_buffer, _buffer_offset + CH8_DISPLAY_WIDTH, buffer_u8, _new_pixel, 2);
            }
            else
            {
                buffer_poke(_display_buffer, _buffer_offset, buffer_u8, _new_pixel);
            }
            
            _bit_pos --;
        }
        if (_collision) _collisions ++;
    }
    
    // If this caused any pixels to be erased, VF is set to 1, otherwise it is set to 0. 
    registers.v[@ 0xF] = _highres ? _collisions : _collisions > 0;
    
    global.display.update_display = true; 
}

ch8_draw_sprite_high_res = function(_xs, _ys)
{
    var _buffer = memory_buffer;
    var _display_buffer = global.display.display_buffer;
    
    var _n = 16;
    var _index = registers.index;
    var _collisions = 0;
    
    for (var _y=0; _y<_n; _y++) // row of 8 pixels
    {
        if (_index + (_y*2) >= CH8_MEMORY_MAX) break;
        
        var _collision = false;
        for (var _b=0; _b<2; _b++)
        {
            // Get the sprite: read 8 bytes from memory, starting at the address stored in I.
            var _byte = buffer_peek(_buffer, _index + (_y*2) + _b, buffer_u8);
            
            // Loop through each bit and set the corresponding byte in the buffer
            var _bit_pos = 7; // reverse the bit order
            for (var _x=0; _x<8; _x++) 
            {
                // Sprite wraps around the screen
                var _buffer_offset = ((_xs + _x + (_b*8)) % CH8_DISPLAY_WIDTH) + (((_ys + _y) % CH8_DISPLAY_HEIGHT) * CH8_DISPLAY_WIDTH);
                
                // Sprites are XORred with existing pixels on the display
                var _old_pixel = buffer_peek(_display_buffer, _buffer_offset, buffer_u8);
                var _new_pixel = (((_byte >> _bit_pos) & 1) * 255) ^ _old_pixel;
            
                // Flag as collision if pixel was deleted or is clipped by the bottom of the screen
                if (!_collision && ((_old_pixel != 0 && _new_pixel == 0) || (_ys + _y >= CH8_DISPLAY_HEIGHT))) 
                    _collision = true;
                
                // Write new color to display buffer
                buffer_poke(_display_buffer, _buffer_offset, buffer_u8, _new_pixel);
            
                _bit_pos --;
            }
        }
        if (_collision) _collisions ++;
    }
    
    // In high resolution mode: sets VF to the number of rows that 
    // either collide with another sprite or are clipped by the bottom of the screen.
    registers.v[@ 0xF] = _collisions;
    
    global.display.update_display = true; 
}

skip_if_key_pressed = function(_vx)
{
    var _key = lut_virtual_keys[? registers.v[_vx] ];
    if (!is_undefined(_key) && keyboard_check(_key))
    {
        registers.pc += 2;
    }
}

skip_if_key_not_pressed = function(_vx)
{
    var _key = lut_virtual_keys[? registers.v[_vx] ];
    if (is_undefined(_key) || !keyboard_check(_key))
    {
        registers.pc += 2;
    }
}

set_var_to_delay = function(_vx)
{
    registers.v[@ _vx] = registers.dt;
}

wait_for_key_press = function(_vx)
{
    waiting_for_key_press = _vx;
}

set_delay_to_var = function(_vx)
{
    registers.dt = registers.v[_vx];
}

set_sound_to_var = function(_vx)
{
    registers.st = registers.v[_vx];
    if (registers.st > 0)
    {
        if (!muted && !audio_is_playing(sound_tone)) audio_play_sound(sound_tone, 0, true);   
    }
}

add_var_to_index = function(_vx)
{
    var _sum = registers.index + registers.v[_vx];
    registers.v[@ 0xF] = _sum > 0xFFF; // VF flag for range overflow
    registers.index = _sum & 0xFFF;
}

set_index_to_var_sprite = function(_vx)
{
    // Set I = location of sprite for digit Vx.
    registers.index = CH8_ADDR_SPR + (registers.v[_vx] * 5);
}

store_bcd_from_var = function(_vx)
{
    // Store BCD representation of Vx in memory locations I, I+1, and I+2.
    // places the hundreds digit in memory at location in I, 
    // the tens digit at location I+1, and the ones digit at location I+2.
    var _num = registers.v[_vx];
    var _index = registers.index;
    var _buffer = memory_buffer;
    buffer_poke(_buffer, _index,    buffer_u8, _num div 100);          // Hundreds digit
    buffer_poke(_buffer, _index+1,  buffer_u8, (_num div 10) mod 10);  // Tens digit
    buffer_poke(_buffer, _index+2,  buffer_u8, _num mod 10);           // Ones digit
}

save_vars_in_memory = function(_vx)
{
    // Store registers V0 ~ Vx in memory starting at location I.
    var _buffer = memory_buffer;
    buffer_seek(_buffer, buffer_seek_start, registers.index);
    var _n = 0;
    repeat(_vx + 1)
    {
        buffer_write(_buffer, buffer_u8, registers.v[_n ++]); 
    }
}

load_vars_from_memory = function(_vx)
{
    // Load values to registers V0 ~ Vx from memory starting at location I.
    var _buffer = memory_buffer;
    buffer_seek(_buffer, buffer_seek_start, registers.index);
    var _n = 0;
    repeat(_vx + 1)
    {
        registers.v[@ _n ++] = buffer_read(_buffer, buffer_u8);
    }
}


#endregion

#region Instruction (SUPERCHIP-8 1.1)

scroll_down = function(_ins)
{
    // Scroll display N pixels down
    var _scroll_amount = _ins & 0xF;
    var _display_buffer = global.display.display_buffer;

    var _bottom_edge = CH8_DISPLAY_HEIGHT - _scroll_amount;
    
    for (var _y=_bottom_edge; _y>=0; _y--)
    {
        var _row_offset = _y * CH8_DISPLAY_WIDTH;
        var _scroll_offset = _scroll_amount * CH8_DISPLAY_WIDTH;
        for (var _x=_scroll_amount; _x<CH8_DISPLAY_WIDTH; _x++)
        {
            var _pixel = buffer_peek(_display_buffer, _x + _row_offset, buffer_u8);
            buffer_poke(_display_buffer, _x + _row_offset + _scroll_offset, buffer_u8, _pixel);
        }
    }
    // Clear old positions
    buffer_fill(_display_buffer, 0, buffer_u8, 0, CH8_DISPLAY_WIDTH * _scroll_amount);
    
    global.display.update_display = true;
}

scroll_left = function(_ins)
{
    // Scroll left by 4 pixels
    var _scroll_amount = 4;
    var _display_buffer = global.display.display_buffer;

    for (var _y=0; _y<CH8_DISPLAY_HEIGHT; _y++)
    {
        var _row_offset = _y*CH8_DISPLAY_WIDTH;
        for (var _x=_scroll_amount; _x<CH8_DISPLAY_WIDTH; _x++)
        {
            var _pixel = buffer_peek(_display_buffer, _x + _row_offset, buffer_u8);
            buffer_poke(_display_buffer, _x + _row_offset - _scroll_amount, buffer_u8, _pixel);
        }
    }
    
    // Clear old positions
    var _right_edge = CH8_DISPLAY_WIDTH - _scroll_amount;
    for (var _y=0; _y<CH8_DISPLAY_HEIGHT; _y++)
    {
        buffer_fill(_display_buffer, (_y * CH8_DISPLAY_WIDTH) + _right_edge, buffer_u8, 0, _scroll_amount);
    }
    
    global.display.update_display = true;
}

scroll_right = function(_ins)
{
    // Scroll right by 4 pixels; in low resolution mode, 2 pixels
    var _scroll_amount = 4;
    var _right_edge = CH8_DISPLAY_WIDTH - _scroll_amount;
    var _display_buffer = global.display.display_buffer;

    for (var _y=0; _y<CH8_DISPLAY_HEIGHT; _y++)
    {
        var _row_offset = _y*CH8_DISPLAY_HEIGHT;
        for (var _x=_right_edge; _x>=0; _x--)
        {
            var _pixel = buffer_peek(_display_buffer, _x + _row_offset, buffer_u8);
            buffer_poke(_display_buffer, _x + _row_offset + _scroll_amount, buffer_u8, _pixel);
        }
    }
    // Clear old positions
    for (var _y=0; _y<CH8_DISPLAY_HEIGHT; _y++)
    {
        buffer_fill(_display_buffer, _y * CH8_DISPLAY_WIDTH, buffer_u8, 0, _scroll_amount);
    }
    
    global.display.update_display = true;
}

exit_interpreter = function(_ins)
{
    interpreter_running = false;
    if (audio_is_playing(sound_tone)) audio_stop_sound(sound_tone);
    
    global.ui.show_popup("Program exited");
}

enable_high_resolution = function(_ins)
{
    high_resolution = true;
}

disable_high_resolution = function(_ins)
{
    high_resolution = false;
}

set_index_to_var_sprite_big = function(_vx)
{
    // Point I to 10-byte font sprite for digit VX (only digits 0-9)
    registers.index = CH8_ADDR_SPR_HIGHRES + (registers.v[_vx] * 10);
}

store_vars_in_rpl = function(_vx)
{
    // Store V0~VX in RPL user flags (X <= 7)
    var _n = 0;
    repeat(_vx + 1)
    {
        registers.rpl[@ _n] = registers.v[_n ++]; 
    }
}

load_vars_from_rpl = function(_vx)
{
    // Read V0~VX from RPL user flags (X <= 7)
    var _n = 0;
    repeat(_vx + 1)
    {
        registers.v[@ _n] = registers.rpl[_n ++]; 
    }
}

#endregion

#region Instructions lookup tables

lut_instructions = lut_create([
    [0x0, ext_system                    ], // refer to lut_system
    [0x1, jump_to_address               ], // 1nnn - JP addr
    [0x2, call_subroutine               ], // 2nnn - CALL addr
    [0x3, skip_if_var_equal_val         ], // 3xkk - SE Vx, byte
    [0x4, skip_if_var_not_equal_val     ], // 4xkk - SNE Vx, byte
    [0x5, skip_if_var_equal_var2        ], // 5xy0 - SE Vx, Vy
    [0x6, set_var_to_val                ], // 6xkk - LD Vx, byte
    [0x7, add_val_to_var                ], // 7xkk - ADD Vx, byte
    [0x8, ext_var                       ], // refer to lut_var
    [0x9, skip_if_var_not_equal_var2    ], // 9xy0 - SNE Vx, Vy
    [0xA, set_index_to_address          ], // Annn - LD I, addr
    [0xB, jump_to_address_plus_val      ], // Bnnn - JP V0, addr
    [0xC, set_var_to_random             ], // Cxkk - RND Vx, byte
    [0xD, ch8_draw_sprite               ], // Dxyn - DRW Vx, Vy, nibble
    [0xE, ext_keyboard                  ], // refer to lut_keyboard
    [0xF, ext_misc                      ], // refer to lut_misc
]);
lut_system = lut_create([
    [0x0E0, clear_display               ], // 00E0 – CLS
    [0x0EE, return_from_subroutine      ], // 00EE – RET
    // SUPERCHIP INSTRUCTIONS
    [0x0FB, scroll_right                ], // 00FB – SCR
    [0x0FC, scroll_left                 ], // 00FC – SCL
    [0x0FD, exit_interpreter            ], // 00FD – EXIT
    [0x0FE, disable_high_resolution     ], // 00FE – LOW
    [0x0FF, enable_high_resolution      ], // 00FF – HIGH
]);
lut_var = lut_create([
    [0x0, set_var_to_var2               ], // 8xy0 - LD Vx, Vy
    [0x1, set_var_to_var_or_var2        ], // 8xy1 - OR Vx, Vy
    [0x2, set_var_to_var_and_var2       ], // 8xy2 - AND Vx, Vy
    [0x3, set_var_to_var_xor_var2       ], // 8xy3 - XOR Vx, Vy
    [0x4, add_var2_to_var               ], // 8xy4 - ADD Vx, Vy
    [0x5, subtract_var2_from_var        ], // 8xy5 - SUB Vx, Vy
    [0x6, shift_right_var               ], // 8xy6 - SHR Vx {, Vy}
    [0x7, subtract_var_from_var2        ], // 8xy7 - SUBN Vx, Vy
    [0xE, shift_left_var                ], // 8xyE - SHL Vx {, Vy}
]);
lut_keyboard = lut_create([
    [0x9E, skip_if_key_pressed          ], // Ex9E - SKP Vx
    [0xA1, skip_if_key_not_pressed      ], // ExA1 - SKNP Vx
]);
lut_misc = lut_create([
    [0x07, set_var_to_delay             ], // Fx07 - LD Vx, DT
    [0x0A, wait_for_key_press           ], // Fx0A - LD Vx, K
    [0x15, set_delay_to_var             ], // Fx15 - LD DT, Vx
    [0x18, set_sound_to_var             ], // Fx18 - LD ST, Vx
    [0x1E, add_var_to_index             ], // Fx1E - ADD I, Vx
    [0x29, set_index_to_var_sprite      ], // Fx29 - LD F, Vx
    [0x33, store_bcd_from_var           ], // Fx33 - LD B, Vx
    [0x55, save_vars_in_memory          ], // Fx55 - LD [I], Vx
    [0x65, load_vars_from_memory        ], // Fx65 - LD Vx, [I]
    // SUPERCHIP INSTRUCTIONS
    [0x30, set_index_to_var_sprite_big  ], // Fx30 - LD HF, Vx
    [0x75, store_vars_in_rpl            ], // Fx75 - LD R, Vx
    [0x85, load_vars_from_rpl           ], // Fx85 - LD Vx, R
]);

#endregion

#region Methods

/// @description Resets the emulator
ch8_initialize = function()
{
    // Clear the memory buffer
    var _buffer = memory_buffer;
    buffer_fill(_buffer, 0, buffer_u8, 0, buffer_get_size(_buffer));
    
    // Clear the display buffer
    var _display_buffer = global.display.display_buffer;
    buffer_fill(_display_buffer, 0, buffer_u8, 0, buffer_get_size(_display_buffer));
    global.display.update_display = true;
    
    // Reset registers and stack
    registers = {
        v :     array_create(16),   // General purpose for 8-bit values
        index : 0x0,                // General purpose for storing addresses (16-bit)
        pc :    CH8_ADDR_PROG,      // Stores the offset of the next instruction
        sp :    CH8_ADDR_STACK,     // Stores the current position of the stack
        stack:  array_create(16),   // Stack of 16-bit addresses
        dt :    0,                  // delay timer
        st :    0,                  // sound timer
        rpl:    array_create(8)     // (superchip only) stores 8-bit values
    }

    program_offset = 0; // Programs are loaded into memory at 0x200, you can specify additional offset
    interpreter_running = false;

    paused = false;
    running_time = 0; // How long the interpreted has been running (secs)
    dt = 0; // culmulative delta time. Reduced by the tick rate every cycle.
    last_delay_time = 0;
    last_sound_time = 0;
    waiting_for_key_press = -1;
    key_press_checked = false;
    high_resolution = false;
    
    instruction_current = 0; // for debugging
    
    // Generate random seed
    randomize();
    
    // Write font sprites into memory
    var _font_arr = font_set;
    var _len = array_length(_font_arr);
    buffer_seek(_buffer, buffer_seek_start, CH8_ADDR_SPR);
    for (var i=0; i<_len; i++)
    {
        buffer_write(_buffer, buffer_u8, _font_arr[i]);
    }
    
    gc_collect();
}

/// @description Loads a CHIP-8 file (.ch8) to the rom buffer.
load_program = function(_fname, _offset = 0)
{
    if (_offset < 0 || _offset > CH8_MEMORY_MAX - CH8_ADDR_PROG) 
    {
        show_message($"Error: offset must be between 0~{CH8_MEMORY_MAX - CH8_ADDR_PROG}\nDefaulting to 0.");
        _offset = 0;
    }
    var _buffer_raw = buffer_load(_fname);
    var _buffer_size = buffer_get_size(_buffer_raw);
    
    if (_buffer_size <= 0 || _buffer_size > CH8_MEMORY_MAX - (CH8_ADDR_PROG + _offset))
    {
        show_message($"Error: Invalid program size.");
        interpreter_running = false;
        return;
    }
    
    var _buffer = memory_buffer;
    buffer_seek(_buffer, buffer_seek_start, CH8_ADDR_PROG + _offset);

    var _byte_pos = 0;
    buffer_copy(_buffer_raw, 0, _buffer_size, _buffer, buffer_tell(_buffer));
    
    if (buffer_exists(_buffer_raw)) buffer_delete(_buffer_raw);
    _buffer_raw = -1;
    
    program_offset = CH8_ADDR_PROG + _offset;
    registers.pc = program_offset;
    
    interpreter_running = true;
}

execute_instruction = function(_ins)
{
    // Get the first digit of the instruction
    var _first_digit = _ins >> 12;
    // Decode the instruction using lookup tables, Then execute it
    lut_instructions[? _first_digit](_ins & 0xFFF); // Send the 3 rightmost digits as an argument
}

/// @description returns the lut key of the first found virtual key that is pressed
get_virtual_key_pressed = function()
{
    for (var i=0x0; i<0xF; i++)
    {
        var _key = lut_virtual_keys[? i];
        if (keyboard_check(_key))
        {
            return i;
        }
    }   
}

///@description Emulates a CPU cycle of the Chip8
run_process = function()
{
    var _running_time = running_time;

    // Play sound
    while (_running_time - last_sound_time > 0.01667)
    {
        last_sound_time = _running_time;
        if (registers.st > 0)
        {
            if (!muted && !audio_is_playing(sound_tone)) audio_play_sound(sound_tone, 0, true);   
            registers.st --;
            if (registers.st <= 0)
            {
                if (audio_is_playing(sound_tone)) audio_stop_sound(sound_tone);
            }
        }
    }
    
    // Delay timer
    while (_running_time - last_delay_time > 0.01667)
    {
        last_delay_time = _running_time;
        if (registers.dt > 0) registers.dt --;
    }
    
    // Halt execution if waiting for key press
    if (waiting_for_key_press != -1)
    {
        if (key_press_checked) return;
        key_press_checked = true; // Allows one key check per frame (game maker updates once per step)
        
        if (keyboard_key == vk_nokey) return;
        var _key_number = get_virtual_key_pressed();
        if (_key_number != -1)
        {
            registers.v[@ waiting_for_key_press] = _key_number;
            waiting_for_key_press = -1;
        }
        else return;
    }
    
    var _buffer = memory_buffer;
    
    // Read the value of the PC register
    var _program_counter = registers.pc;
    // Fetch an instruction (2 bytes) from the buffer at the offset (aka address) PC
    var _ins = buff_peek_number_be_16(_buffer, _program_counter);
    
    // Debug stuff
    if (ch8_debug_mode) 
    {
        instruction_current = _ins;
    }
    
    // Move the PC register to the next operation 2 bytes forward
    registers.pc += 2;
    
    // Execute the command encoded by the instruction
    execute_instruction(_ins);
    if (!interpreter_running) 
    {
        ch8_initialize();
        return;
    }
}


#endregion

#region Initialize

//show_debug_overlay(false);

#endregion