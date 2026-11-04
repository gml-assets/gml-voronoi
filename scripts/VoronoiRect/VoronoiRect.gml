/// @func VoronoiRect(_left, _top, _right, _bottom)
/// @desc An axis-aligned rectangle. The sides are sorted, so any two opposite corners work
/// @param {Real} _left
/// @param {Real} _top
/// @param {Real} _right
/// @param {Real} _bottom
function VoronoiRect(_left, _top, _right, _bottom) constructor {
  left   = min(_left, _right);
  top    = min(_bottom, _top);
  right  = max(_left, _right);
  bottom = max(_bottom, _top);
}
