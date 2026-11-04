/// @func Point2D(_x, _y)
function Point2D(_x, _y) constructor {
  x = _x;
  y = _y;
  
  /// @func is_equal(_p)
  static is_equal = function(_p) {
    return x == _p.x and y == _p.y;
  }
}
