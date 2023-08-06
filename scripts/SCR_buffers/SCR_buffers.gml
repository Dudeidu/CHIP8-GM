
function buff_peek_number_be_16(_buffer, _offset) 
{
    return (buffer_peek(_buffer, _offset, buffer_u8) << 8) 
           | buffer_peek(_buffer, _offset + 1, buffer_u8);
}

function buff_poke_number_be_16(_buffer, _offset, _value) 
{
    buffer_poke(_buffer, _offset, buffer_u8, _value >> 8);
    buffer_poke(_buffer, _offset + 1, buffer_u8, _value & 0xFF);
}



