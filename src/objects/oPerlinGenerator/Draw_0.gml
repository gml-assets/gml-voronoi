/// @desc Draw noise
if (surface_exists(surf) && keyboard_check(ord("Q"))) {
    draw_surface(surf, mouse_x + _debug_surf_off, mouse_y);
}
