/// @desc Generate perlin noise
if (!generated) {
    surf = surface_create(size, size);
    
    surface_set_target(surf);
    shader_set(shdr_noise_perlin_2d);
        shader_set_uniform_f(u_resolution, size, size);
        shader_set_uniform_f(u_seed, seed);
        shader_set_uniform_f(u_persistence, persistence);
        shader_set_uniform_f(u_freq, frequency);
        shader_set_uniform_f(u_scale, scale);
        shader_set_uniform_f(u_xoffset, xoff);
        shader_set_uniform_f(u_yoffset, yoff);
        
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(0, 0, size, size, false);
        
        shader_reset();
    surface_reset_target();
    
    // Noise is greyscale, so any channel will do
    buffer_get_surface(surf_buffer, surf, 0);
    for (var _i = 0; _i < sqr(size); ++_i) {
        buffer_poke(buffer, _i, buffer_u8, buffer_peek(surf_buffer, _i * 4, buffer_u8));
    }
    
    generated = true;
} else if (!surface_exists(surf)) {
    surf = surface_create(size, size);
    
    for (var _i = 0; _i < sqr(size); ++_i) {
        var _v = buffer_peek(buffer, _i, buffer_u8);
        buffer_poke(surf_buffer, _i * 4, buffer_u32, $ff000000 | (_v << 16) | (_v << 8) | _v);
    }
    buffer_set_surface(surf_buffer, surf, 0);
}
