/// @func VoronoiHalton(_halton_base, [_halton_seed])
/// @desc Halton sequence: evenly spread numbers in [0, 1)
/// @param {Real} _halton_base a prime, a different one for each dimension
/// @param {Real} [_halton_seed] index of the first number, the sign is ignored
function VoronoiHalton(_halton_base, _halton_seed = 1) constructor {
  halton_base = _halton_base;
  halton_seed = abs(floor(_halton_seed));

  /// @func get_next()
  /// @desc The next number of the sequence
  /// @returns {Real}
  static get_next = function() {
    var _out = 0;
    var _f = 1 / halton_base;

    var _i = halton_seed;
    while (_i > 0) {
      _out += _f * (_i % halton_base);
      _i = floor(_i / halton_base);
      _f /= halton_base;
    }

    ++halton_seed;

    return _out;
  }
}
