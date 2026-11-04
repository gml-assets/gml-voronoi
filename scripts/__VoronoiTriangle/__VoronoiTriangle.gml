/// @func __VoronoiTriangle(_p1, _p2, _p3)
/// @desc A triangle of the triangulation, with its centroid and circumcircle
/// @param {Struct.VoronoiPoint} _p1
/// @param {Struct.VoronoiPoint} _p2
/// @param {Struct.VoronoiPoint} _p3
function __VoronoiTriangle(_p1, _p2, _p3) constructor {
  /// @func circumcircle_x(_x1, _y1, _x2, _y2, _x3, _y3)
  /// @desc X of the circumcircle centre
  /// @returns {Real}
  static circumcircle_x = function(_x1, _y1, _x2, _y2, _x3, _y3) {
    var _a = _x1 * _x1 + _y1 * _y1;
    var _b = _x2 * _x2 + _y2 * _y2;
    var _c = _x3 * _x3 + _y3 * _y3;

    var _cx = _a * (_y3 - _y2) + _b * (_y1 - _y3) + _c * (_y2 - _y1);
    _cx /= _x1 * (_y3 - _y2) + _x2 * (_y1 - _y3) + _x3 * (_y2 - _y1);

    return _cx / 2;
  };

  /// @func circumcircle_y(_x1, _y1, _x2, _y2, _x3, _y3)
  /// @desc Y of the circumcircle centre
  /// @returns {Real}
  static circumcircle_y = function(_x1, _y1, _x2, _y2, _x3, _y3) {
    var _a = _x1 * _x1 + _y1 * _y1;
    var _b = _x2 * _x2 + _y2 * _y2;
    var _c = _x3 * _x3 + _y3 * _y3;

    var _cy = _a * (_x3 - _x2) + _b * (_x1 - _x3) + _c * (_x2 - _x1);
    _cy /= _y1 * (_x3 - _x2) + _y2 * (_x1 - _x3) + _y3 * (_x2 - _x1);

    return _cy / 2;
  };

  points = [_p1, _p2, _p3];

  center_x = (_p1.x + _p2.x + _p3.x) / 3;
  center_y = (_p1.y + _p2.y + _p3.y) / 3;

  circumcenter_x = circumcircle_x(_p1.x, _p1.y, _p2.x, _p2.y, _p3.x, _p3.y);
  circumcenter_y = circumcircle_y(_p1.x, _p1.y, _p2.x, _p2.y, _p3.x, _p3.y);

  circumradius = point_distance(_p1.x, _p1.y, circumcenter_x, circumcenter_y);
}
