/// @func voronoi_in_rect(_voronoi, _left, _top, _right, _bottom)
/// @desc Clips the cells to the rect in place. Drops the cells left outside and clamps the sites
/// @param {Array<Struct>} _voronoi from voronoi_from_delaunay
/// @param {Real} _left
/// @param {Real} _top
/// @param {Real} _right
/// @param {Real} _bottom
function voronoi_in_rect(_voronoi, _left, _top, _right, _bottom) {
    var _voronoi_n = array_length(_voronoi);
    
    for (var _i = 0; _i < _voronoi_n; ++_i) {
        var _vertices = array_map(_voronoi[_i].polygon, function(_edge) {
            return _edge[0];
        });
        
        _vertices = __voronoi_clip_axis(_vertices, "x", _left, true);
        _vertices = __voronoi_clip_axis(_vertices, "x", _right, false);
        _vertices = __voronoi_clip_axis(_vertices, "y", _top, true);
        _vertices = __voronoi_clip_axis(_vertices, "y", _bottom, false);
        
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
        
        _site.x = clamp(_site.x, _left, _right);
        _site.y = clamp(_site.y, _top, _bottom);
    }
}

/// @func __voronoi_clip_axis(_vertices, _axis, _value, _keep_greater)
/// @desc Clips a polygon against an axis-aligned line, one Sutherland-Hodgman step
/// @param {Array<Struct>} _vertices
/// @param {String} _axis "x" or "y"
/// @param {Real} _value position of the line
/// @param {Bool} _keep_greater keep the side with coordinates >= _value
/// @returns {Array<Struct>}
function __voronoi_clip_axis(_vertices, _axis, _value, _keep_greater) {
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
            var _cross = { x: lerp(_prev.x, _curr.x, _t), y: lerp(_prev.y, _curr.y, _t) };
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
