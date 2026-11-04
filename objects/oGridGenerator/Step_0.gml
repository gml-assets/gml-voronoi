/// @desc Controls
if (keyboard_check_pressed(vk_space)) room_restart();

if (keyboard_check_pressed(ord("S")) && seed_dialog == -1) {
  seed_dialog = get_string_async("Seed:", string(seed));
}

for (var _i = 0; _i < 4; ++_i) {
  if (keyboard_check_pressed(ord("1") + _i)) map_view = _i;
}
