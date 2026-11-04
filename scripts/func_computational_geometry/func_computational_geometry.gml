/// @func delaunay_bowyer_watson(_points, [_margin])
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
  var _super_triangle = new Triangle(
    new Point2D(_aabb_left - _hw, _aabb_bottom),
    new Point2D(_aabb_left + _hw, _aabb_top - _h),
    new Point2D(_aabb_right + _hw, _aabb_bottom)
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
      array_push(_triangulation, new Triangle(
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

/// @func voronoi_from_delaunay(_points, _triangulation)
function voronoi_from_delaunay(_points, _triangulation) {
  var _triangulation_n = array_length(_triangulation);
  var _points_n = array_length(_points);
  var _triangles_lookup = array_create_ext(_points_n, function() { return []; });

  // Initialize the lookup table
  for (var _i = 0; _i < _triangulation_n; ++_i) {
    var _j = 0;

    repeat (3) {
      var _idx = array_get_index(_points, _triangulation[_i].points[_j++]);
      if (_idx != -1) array_push(_triangles_lookup[_idx], _i);
    }
  }

  // For every point, sort triangles in clockwise order
  for (var _i = 0; _i < _points_n; ++_i) {
    var _p = _points[_i];
    var _triangles = _triangles_lookup[_i];

    array_sort(_triangles, method({_p, _triangulation}, function(_idx1, _idx2) {
      var _el1 = _triangulation[_idx1];
      var _el2 = _triangulation[_idx2];
      
      var _theta1 = point_direction(_p.x, _p.y, _el1.center_x, _el1.center_y);
      var _theta2 = point_direction(_p.x, _p.y, _el2.center_x, _el2.center_y);
      
      return _theta2 - _theta1;
    }));
  }

  // Create the voronoi diagram
  var _voronoi = [];

  for (var _i = 0; _i < _points_n; ++_i) {
    var _p = _points[_i];

    var _triangles = _triangles_lookup[_i];
    var _triangles_n = array_length(_triangles);

    if (_triangles_n < 3) continue; // Degenerate case

    var _polygon = [];
    
    for (var _j = 0; _j < _triangles_n; ++_j) {
      var _tri = _triangulation[_triangles[_j]];
      var _tri_next = _triangulation[_triangles[(_j + 1) % _triangles_n]];

      var _edge = [
        new Point2D(_tri.circumcenter_x, _tri.circumcenter_y),
        new Point2D(_tri_next.circumcenter_x, _tri_next.circumcenter_y)
      ];

      array_push(_polygon, _edge);
    }

    array_push(_voronoi, {
      site: _p,
      polygon: _polygon,
    });
  }

  return _voronoi;
}

/// @func voronoi_in_rect(_voronoi, _rect)
function voronoi_in_rect(_voronoi, _rect) {
  var _voronoi_n = array_length(_voronoi);

  for (var _i = 0; _i < _voronoi_n; ++_i) {
    var _vertices = array_map(_voronoi[_i].polygon, function(_edge) {
      return _edge[0];
    });

    _vertices = polygon_clip_axis(_vertices, "x", _rect.left, true);
    _vertices = polygon_clip_axis(_vertices, "x", _rect.right, false);
    _vertices = polygon_clip_axis(_vertices, "y", _rect.top, true);
    _vertices = polygon_clip_axis(_vertices, "y", _rect.bottom, false);

    var _vertices_n = array_length(_vertices);
    var _polygon_clipped = array_create(_vertices_n);

    for (var _j = 0; _j < _vertices_n; ++_j) {
      _polygon_clipped[_j] = [_vertices[_j], _vertices[(_j + 1) % _vertices_n]];
    }

    _voronoi[_i].polygon = _polygon_clipped;
  }

  // Remove empty polygons
  var _n = _voronoi_n;
  while (_n--) {
    if (array_length(_voronoi[_n].polygon) < 3) {
      array_delete(_voronoi, _n, 1);
      --_voronoi_n;
    }
  }

  for (var _i = 0; _i < _voronoi_n; ++_i) {
    var _site = _voronoi[_i].site;

    _site.x = clamp(_site.x, _rect.left, _rect.right);
    _site.y = clamp(_site.y, _rect.top, _rect.bottom);
  }
}

/// @func polygon_clip_axis(_vertices, _axis, _value, _keep_greater)
/// @param {Array<Struct.Point2D>} _vertices
/// @param {String} _axis "x" or "y"
/// @param {Real} _value Position of the clipping line
/// @param {Bool} _keep_greater Keep the side with coordinates >= _value
function polygon_clip_axis(_vertices, _axis, _value, _keep_greater) {
  var _vertices_n = array_length(_vertices);
  var _out = [];
  if (_vertices_n == 0) return _out;

  var _is_x = _axis == "x";

  var _prev = _vertices[_vertices_n - 1];
  var _prev_c = _is_x ? _prev.x : _prev.y;
  var _prev_in = _keep_greater ? (_prev_c >= _value) : (_prev_c <= _value);

  for (var _i = 0; _i < _vertices_n; ++_i) {
    var _curr = _vertices[_i];
    var _curr_c = _is_x ? _curr.x : _curr.y;
    var _curr_in = _keep_greater ? (_curr_c >= _value) : (_curr_c <= _value);

    if (_curr_in != _prev_in) {
      var _t = (_value - _prev_c) / (_curr_c - _prev_c);
      var _cross = new Point2D(lerp(_prev.x, _curr.x, _t), lerp(_prev.y, _curr.y, _t));
      if (_is_x) _cross.x = _value; else _cross.y = _value;

      array_push(_out, _cross);
    }

    if (_curr_in) array_push(_out, _curr);

    _prev = _curr;
    _prev_c = _curr_c;
    _prev_in = _curr_in;
  }

  return _out;
}

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
      _points[_i] = new Point2D(_site.x, _site.y);
    } else {
      _points[_i] = new Point2D(_center_x / (3 * _area), _center_y / (3 * _area));
    }
  }

  return _points;
}
