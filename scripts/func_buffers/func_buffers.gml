/// @func buffer_normalize_values(_buff, _buff_data_type, _buff_size, _in_min, _in_max, [_out_min], [_out_max])
/// @desc Maps every value from the input range to the output range, clamped and rounded
/// @param {Id.Buffer} _buff
/// @param {Constant.BufferDataType} _buff_data_type
/// @param {Real} _buff_size number of values
/// @param {Real} _in_min
/// @param {Real} _in_max
/// @param {Real} [_out_min]
/// @param {Real} [_out_max]
function buffer_normalize_values(_buff, _buff_data_type, _buff_size, _in_min, _in_max, _out_min = 0, _out_max = 1) {
  buffer_seek(_buff, buffer_seek_start, 0);
  repeat (_buff_size) {
    var _pos = buffer_tell(_buff);
    var _val = real(buffer_peek(_buff, _pos, _buff_data_type));
    
    _val = map_value(_val, _in_min, _in_max, _out_min, _out_max);
    _val = round(clamp(_val, _out_min, _out_max));
    
    buffer_write(_buff, _buff_data_type, _val);
  }
}

/// @func buffer_get_median(_buff, _buff_data_type, _buff_size)
/// @desc The median of the values
/// @param {Id.Buffer} _buff
/// @param {Constant.BufferDataType} _buff_data_type
/// @param {Real} _buff_size number of values
/// @returns {Real}
function buffer_get_median(_buff, _buff_data_type, _buff_size) {
  var _arr = array_create(_buff_size);
  buffer_seek(_buff, buffer_seek_start, 0);
  
  var _i = 0;
  repeat (_buff_size) {
    _arr[_i++] = buffer_read(_buff, _buff_data_type);
  }
  
  array_sort(_arr, true);
  
  return _arr[_buff_size div 2];
}

/// @func buffer_change_median(_buff, _buff_data_type, _buff_size, _in_min, _in_max, _median)
/// @desc Remaps the values so their median becomes _median, keeping the range
/// @param {Id.Buffer} _buff
/// @param {Constant.BufferDataType} _buff_data_type
/// @param {Real} _buff_size number of values
/// @param {Real} _in_min
/// @param {Real} _in_max
/// @param {Real} _median
function buffer_change_median(_buff, _buff_data_type, _buff_size, _in_min, _in_max, _median) {
  var _median_curr = buffer_get_median(_buff, _buff_data_type, _buff_size);
  
  buffer_seek(_buff, buffer_seek_start, 0);
  for (var _i = 0; _i < _buff_size; ++_i) {
    var _pos = buffer_tell(_buff);
    var _val = buffer_peek(_buff, _pos, _buff_data_type);
    
    if (_val <= _median_curr) {
      _val = map_value(_val, _in_min, _median_curr, _in_min, _median);
    } else {
      _val = map_value(_val, _median_curr + 1, _in_max, _median + 1, _in_max);
    }
    _val = round(_val);
    
    buffer_write(_buff, _buff_data_type, _val);
  }
}
