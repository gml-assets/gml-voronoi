/// @desc Await for noise generation
var _t = get_timer();
switch (step) {
  case 0:
    var _halton_2d = [new VoronoiHalton(2, seed), new VoronoiHalton(3, seed)];
    
    // Populate point list
    repeat (400) {
      var _x = _halton_2d[0].get_next() * w;
      var _y = _halton_2d[1].get_next() * h;
      array_push(points, new VoronoiPoint(_x, _y));
    }
    
    // Fixed bounds, so every point has a closed cell
    var _m = 32;
    bounds = [
      new VoronoiPoint(-_m, -_m),
      new VoronoiPoint(w + _m, -_m),
      new VoronoiPoint(-_m, h + _m),
      new VoronoiPoint(w + _m, h + _m),
    ];

    alarm[0] = 1;
    ++step;
  break;

  case 1:
  case 2:
  case 3:
  case 4:
    delaunay = delaunay_bowyer_watson(array_concat(points, bounds), 512);
    voronoi = voronoi_from_delaunay(points, delaunay);
    voronoi_in_rect(voronoi, new VoronoiRect(0, 0, w, h));

    if (step < 4) {
      points = lloyd_relaxation(voronoi);
    } else {
      // Init cell params
      for (var _i = 0; _i < array_length(voronoi); ++_i) {
        voronoi[_i].biome = BiomeType.Water;
      }
    }

    alarm[0] = 1;
    ++step;
  break;
  
  case 5:
    if (noise_elevation.generated && noise_elevation_buffer == -1) {
      noise_elevation_buffer = noise_elevation.buffer;
    }
    
    if (noise_precipitation.generated && noise_precipitation_buffer == -1) {
      noise_precipitation_buffer = noise_precipitation.buffer;
    }
    
    if (noise_temperature.generated && noise_temperature_buffer == -1) {
      noise_temperature_buffer = noise_temperature.buffer;
    }
    
    if (noise_elevation_buffer != -1 && noise_precipitation_buffer != -1 && noise_temperature_buffer != -1) {
      ++step;
    }
    
    alarm[0] = 1;
  break;
  
  case 6:
    var _min = 255;
    var _max = 0;
    
    #region Apply gaussian kernel
    buffer_seek(noise_elevation_buffer, buffer_seek_start, 0);
    for (var _y = 0; _y < noise_size; ++_y) {
      for (var _x = 0; _x < noise_size; ++_x) {
        var _value = real(buffer_peek(noise_elevation_buffer, _x + _y * noise_size, buffer_u8));
        
        _value = round(gauss_kernel[_x][_y] * _value);
        
        _min = min(_min, _value);
        _max = max(_max, _value);
        
        buffer_write(noise_elevation_buffer, buffer_u8, _value);
      }
    }
    #endregion
    
    #region Normalize between 0 and 255
    buffer_normalize_values(noise_elevation_buffer, buffer_u8, sqr(noise_size), _min, _max, 0, 255);
    #endregion
    
    #region Redistribute values to make half of the cells water and half land
    buffer_change_median(noise_elevation_buffer, buffer_u8, sqr(noise_size), 0, 255, SEA_LEVEL - 1);
    #endregion
    
    #region Apply gaussian kernel
    buffer_seek(noise_precipitation_buffer, buffer_seek_start, 0);
    for (var _y = 0; _y < noise_size; ++_y) {
      for (var _x = 0; _x < noise_size; ++_x) {
        var _value = real(buffer_peek(noise_precipitation_buffer, _x + _y * noise_size, buffer_u8));
        
        _value = round(255 - gauss_kernel[_x][_y] * _value);
        
        buffer_write(noise_precipitation_buffer, buffer_u8, _value);
      }
    }
    #endregion
    
    #region Warp linear gradient
    var _lin = linspace(0, 255, noise_size);
    
    buffer_seek(noise_temperature_buffer, buffer_seek_start, 0);
    for (var _y = 0; _y < noise_size; ++_y) {
      for (var _x = 0; _x < noise_size; ++_x) {
        var _val = buffer_peek(noise_temperature_buffer, _x + _y * noise_size, buffer_u8);
        
        _val = round(lerp(_lin[_y], _val, .25));
        
        buffer_write(noise_temperature_buffer, buffer_u8, _val);
      }
    }
    #endregion
    
    alarm[0] = 1;
    ++step;
  break;
  
  case 7:
    #region Sample land/water from elevation noise
    for (var _i = 0; _i < array_length(voronoi); ++_i) {
      var _el = voronoi[_i];
      
      var _x = floor((_el.site.x / w) * (noise_size - 1));
      var _y = floor((_el.site.y / h) * (noise_size - 1));
      
      var _v = buffer_peek(noise_elevation_buffer, _x + _y * noise_size, buffer_u8);
      
      // Assign base biome
      _el.elevation = _v;
      _el.biome = (_v < SEA_LEVEL) ? BiomeType.Water : BiomeType.Land;
    }
    #endregion
    
    #region Mark frontier cells as water
    for (var _i = 0; _i < array_length(voronoi); ++_i) {
      var _el = voronoi[_i];
      
      // If at least one point is on boundary, then
      // the polygon is a frontier polygon
      var _frontier = false;
      
      var _polygon = _el.polygon;
      for (var _j = 0; _j < array_length(_polygon) && !_frontier; ++_j) {
        var _edge = _polygon[_j];
        
        var _k = 0;
        repeat (2) {
          var _ex = _edge[_k].x;
          var _ey = _edge[_k].y;
          
          if (_ex == 0 || _ex == w || _ey == 0 || _ey == h) {
            _frontier = true;
          }
          
          ++_k;
        }
      }
      
      // Convert to water cell
      if (_frontier) _el.biome = BiomeType.Water;
    }
    #endregion
    
    alarm[0] = 1;
    ++step;
  break;
  
  case 8:
    var _min_prec = 255;
    var _min_temp = 255;
    
    var _max_prec = 0;
    var _max_temp = 0;
    
    #region Normalize between 0 and 255
    buffer_seek(noise_elevation_buffer, buffer_seek_start, 0);
    
    buffer_seek(noise_precipitation_buffer, buffer_seek_start, 0);
    buffer_seek(noise_temperature_buffer, buffer_seek_start, 0);
    
    repeat (sqr(noise_size)) {
      var _elev = buffer_read(noise_elevation_buffer, buffer_u8);
      
      var _prec = buffer_read(noise_precipitation_buffer, buffer_u8);
      var _temp = buffer_read(noise_temperature_buffer, buffer_u8);
      
      if (_elev >= SEA_LEVEL) {
        _min_prec = min(_min_prec, _prec);
        _max_prec = max(_max_prec, _prec);
        
        _min_temp = min(_min_temp, _temp);
        _max_temp = max(_max_temp, _temp);
      }
    }
    
    buffer_normalize_values(noise_precipitation_buffer, buffer_u8, sqr(noise_size), _min_prec, _max_prec, 0, 255);
    buffer_normalize_values(noise_temperature_buffer, buffer_u8, sqr(noise_size), _min_temp, _max_temp, 0, 255);
    #endregion
    
    // Free the noise surfaces, they are recreated from the updated buffers
    with (oPerlinGenerator) {
      if (surface_exists(surf)) surface_free(surf);
      surf = -1;
    }
    
    alarm[0] = 1;
    ++step;
  break;
  
  case 9:
    #region Assign biomes based on temperature and precipitation
    for (var _i = 0; _i < array_length(voronoi); ++_i) {
      var _el = voronoi[_i];
      
      var _x = floor((_el.site.x / w) * (noise_size - 1));
      var _y = floor((_el.site.y / h) * (noise_size - 1));
      
      var _temp = buffer_peek(noise_temperature_buffer, _x + _y * noise_size, buffer_u8);
      var _prec = buffer_peek(noise_precipitation_buffer, _x + _y * noise_size, buffer_u8);

      _el.temperature = _temp;
      _el.precipitation = _prec;

      if (_el.biome == BiomeType.Land) {
        _el.biome = whittaker_diagram(real(_temp), real(_prec));
      }
    }
    #endregion
    
    ++step;
    done = true;
  break;
}
show_debug_message($"Step {step} took {(get_timer() - _t) / 1000} ms");
