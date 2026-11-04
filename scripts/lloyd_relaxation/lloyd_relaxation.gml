/// @func lloyd_relaxation(_voronoi)
function lloyd_relaxation(_voronoi) {
  var _voronoi_n = array_length(_voronoi);
  var _points = array_create(_voronoi_n);

  for (var _i = 0; _i < _voronoi_n; ++_i) {
    var _polygon = _voronoi[_i].polygon;
    var _polygon_n = array_length(_polygon);

    var _area = 0;
    var _center_x = 0;
    var _center_y = 0;

    for (var _j = 0; _j < _polygon_n; ++_j) {
      var _p0 = _polygon[_j][0];
      var _p1 = _polygon[_j][1];
      var _cross = _p0.x * _p1.y - _p1.x * _p0.y;

      _area += _cross;
      _center_x += (_p0.x + _p1.x) * _cross;
      _center_y += (_p0.y + _p1.y) * _cross;
    }

    if (_area == 0) {
      var _site = _voronoi[_i].site;
      _points[_i] = new VoronoiPoint(_site.x, _site.y);
    } else {
      _points[_i] = new VoronoiPoint(_center_x / (3 * _area), _center_y / (3 * _area));
    }
  }

  return _points;
}
