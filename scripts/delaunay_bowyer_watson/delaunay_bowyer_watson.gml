/// @func delaunay_bowyer_watson(_points, [_margin])
/// @desc Delaunay triangulation of the points (Bowyer-Watson)
/// @param {Array<Struct.VoronoiPoint>} _points
/// @param {Real} [_margin] space between the points and the starting super triangle
/// @returns {Array<Struct.__VoronoiTriangle>}
function delaunay_bowyer_watson(_points, _margin = 32) {
  var _points_n = array_length(_points);
  if (_points_n < 3) return []; // Not enough points for a triangle

  var _triangulation = [];
  var _triangulation_n = 0;

  #region Use aabb of the points as the super triangle
  var _p = _points[0];

  var _aabb_left   = _p.x;
  var _aabb_top    = _p.y;
  var _aabb_right  = _p.x;
  var _aabb_bottom = _p.y;

  for (var _i = 1; _i < _points_n; ++_i) {
    _p = _points[_i];

    _aabb_left   = min(_aabb_left,   _p.x);
    _aabb_top    = min(_aabb_top,    _p.y);
    _aabb_right  = max(_aabb_right,  _p.x);
    _aabb_bottom = max(_aabb_bottom, _p.y);
  }

  // Add margin to the aabb
  _aabb_left   -= _margin;
  _aabb_top    -= _margin;
  _aabb_right  += _margin;
  _aabb_bottom += _margin;
  #endregion
  
  #region Add super triangle
  var _hw = (_aabb_right - _aabb_left) * 0.5;
  var _h  = _aabb_bottom - _aabb_top;

  // Super triangle
  var _super_triangle = new __VoronoiTriangle(
    new VoronoiPoint(_aabb_left - _hw, _aabb_bottom),
    new VoronoiPoint(_aabb_left + _hw, _aabb_top - _h),
    new VoronoiPoint(_aabb_right + _hw, _aabb_bottom)
  );

  array_push(_triangulation, _super_triangle);
  ++_triangulation_n;
  #endregion

  var _bad_triangles = [];
  var _bad_triangles_n = 0;
  
  for (var _i = 0; _i < _points_n; ++_i) {
    _p = _points[_i];
    
    #region Find all the triangles that are no longer valid due to the insertion
    _bad_triangles = [];
    _bad_triangles_n = 0;
    
    for (var _j = 0; _j < _triangulation_n; ++_j) {
      var _tri = _triangulation[_j];

      if (point_distance(_p.x, _p.y, _tri.circumcenter_x, _tri.circumcenter_y) <= _tri.circumradius) {
        array_push(_bad_triangles, _j);
        ++_bad_triangles_n;
      }
    }
    #endregion

    // Find the boundary of the polygonal hole
    var _polygon = [];

    for (var _j = 0; _j < _bad_triangles_n; ++_j) {
      var _tri = _triangulation[_bad_triangles[_j]];
      var _p1 = _tri.points[2];
      
      // For each edge in the current bad triangle
      for (var _m = 0; _m < 3; ++_m) {
        var _p2 = _tri.points[_m];
        
        var _shared = false;
        for (var _k = 0; _k < _bad_triangles_n && !_shared; ++_k) {
          if (_k == _j) continue;
          
          var _tri_other = _triangulation[_bad_triangles[_k]];
          var _p3 = _tri_other.points[2];
          
          for (var _n = 0; _n < 3 && !_shared; ++_n) {
            var _p4 = _tri_other.points[_n];
            
            if (_p1.is_equal(_p4) && _p2.is_equal(_p3)) || (_p2.is_equal(_p4) && _p1.is_equal(_p3)) {
              _shared = true;
            }

            _p3 = _p4;
          }
        }
        
        if (!_shared) {
          array_push(_polygon, [_p1, _p2]);
        }

        _p1 = _p2;
      }
    }

    // Remove bad triangles from triangulation (indices are ascending)
    var _j = _bad_triangles_n;
    while (_j--) {
      _triangulation[_bad_triangles[_j]] = array_last(_triangulation);
      array_pop(_triangulation);
    }
    _triangulation_n -= _bad_triangles_n;

    // Re-triangulate the polygonal hole
    for (var _j = 0; _j < array_length(_polygon); ++_j) {
      array_push(_triangulation, new __VoronoiTriangle(
        _polygon[_j][0],
        _polygon[_j][1],
        _p
      ));
      ++_triangulation_n;
    }
  }

  // Remove super triangle
  for (var _i = 0; _i < _triangulation_n; ++_i) {
    var _tri = _triangulation[_i];

    for (var _j = 0; _j < 3; ++_j) {
      _p = _tri.points[_j];
      
      if (_p.is_equal(_super_triangle.points[0]) || _p.is_equal(_super_triangle.points[1]) || _p.is_equal(_super_triangle.points[2])) {
        _triangulation[_i] = undefined;
        break;
      }
    }
  }

  var _n = _triangulation_n;
  while (_n--) {
    if (_triangulation[_n] == undefined) {
      array_delete(_triangulation, _n, 1);
      --_triangulation_n;
    }
  }

  return _triangulation;
}
