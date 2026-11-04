/// @desc Draw info panel
var _view_names = ["Biomes", "Elevation", "Temperature", "Precipitation"];

var _x = (off_w * 2 + w) * 2;
var _y = off_h * 2;
var _line = string_height("M") + 4;

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_text(_x, _y, $"Seed: {seed}");
_y += _line * 2;

var _help = [
    "[Space] New map",
    "[S] Enter seed",
    $"[1-4] View: {_view_names[map_view]}",
    "[Q] Hold to show noise maps",
    "[D] Hold to show triangulation",
];

for (var _i = 0; _i < array_length(_help); ++_i) {
    draw_text(_x, _y, _help[_i]);
    _y += _line;
}

if (!done) {
    var _bottom = (off_h + h) * 2;
    draw_healthbar(
        _x, _bottom - 16, display_get_gui_width() - off_w * 2, _bottom,
        (step / 9) * 100,
        c_black, c_red, c_lime,
        0, true, true
    );
}
