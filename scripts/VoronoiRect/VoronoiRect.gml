/// @func VoronoiRect(_left, _top, _right, _bottom)
function VoronoiRect(_left, _top, _right, _bottom) constructor {
  left   = min(_left, _right);
  top    = min(_bottom, _top);
  right  = max(_left, _right);
  bottom = max(_bottom, _top);
}
