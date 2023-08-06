
if (buffer_exists(memory_buffer))               buffer_delete(memory_buffer);

if (ds_exists(lut_virtual_keys, ds_type_map))   ds_map_destroy(lut_virtual_keys);
if (ds_exists(lut_instructions, ds_type_map))   ds_map_destroy(lut_instructions);
if (ds_exists(lut_system, ds_type_map))         ds_map_destroy(lut_system);
if (ds_exists(lut_var, ds_type_map))            ds_map_destroy(lut_var);
if (ds_exists(lut_keyboard, ds_type_map))       ds_map_destroy(lut_keyboard);
if (ds_exists(lut_misc, ds_type_map))           ds_map_destroy(lut_misc);