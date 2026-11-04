/// @func VoronoiPoint(_x, _y)
/// @desc A point on the plane
/// @param {Real} _x
/// @param {Real} _y
function VoronoiPoint(_x, _y) constructor {
    x = _x;
    y = _y;
    
    /// @func is_equal(_p)
    /// @desc Whether both coordinates match
    /// @param {Struct.VoronoiPoint} _p
    /// @returns {Bool}
    static is_equal = function(_p) {
        return x == _p.x and y == _p.y;
    }
}
