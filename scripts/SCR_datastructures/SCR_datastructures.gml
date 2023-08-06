function lut_create(_pairs_arr)
{
    var _lut = ds_map_create();
    var _sz = array_length(_pairs_arr);
    for (var i=0; i<_sz; i++)
    {
        ds_map_add(_lut, _pairs_arr[i][0], _pairs_arr[i][1]);
    }
    return _lut;
}