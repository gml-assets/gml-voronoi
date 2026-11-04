/// @func voronoi_from_delaunay(_points, _triangulation)
/// @desc Voronoi cells of the points. Points in fewer than 3 triangles get no cell
/// @param {Array<Struct>} _points the triangulated points to make cells for
/// @param {Array<Struct.__VoronoiTriangle>} _triangulation from delaunay_bowyer_watson
/// @returns {Array<Struct>} cells as { site, polygon }, the polygon is an array of [{ x, y }, { x, y }] edges
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
                { x: _tri.circumcenter_x, y: _tri.circumcenter_y },
                { x: _tri_next.circumcenter_x, y: _tri_next.circumcenter_y }
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
