/// @description 

if (!interpreter_running || paused) exit;

key_press_checked = false;

var _dt = min(0.167, delta_time / 1000000); // Limit delta time to 10 fps
dt += _dt; 
var _sp = tick_rate / tick_rate_modifier;
while(dt > _sp)
{
    running_time += _sp;
    dt -= _sp;
    
    run_process();
}






