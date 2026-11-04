/// @desc Enter seed
if (async_load[? "id"] != seed_dialog) exit;
seed_dialog = -1;

var _seed = string_digits(async_load[? "result"]);
if (async_load[? "status"] && _seed != "") {
    global.next_seed = real(_seed);
    room_restart();
}
