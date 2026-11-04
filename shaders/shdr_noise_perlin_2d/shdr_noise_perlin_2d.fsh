// Adapted for GMS by Cem Baspinar. Shadertoy page for it linked below.
//
// A Note from @aft:
// On the page linked below, you will see a discussion that reveals
// Stefan Gustavson's opinion on adding a seed support. He himself
// says that it has a performance cost and this shall be done by
// offsetting coords. This code is a coordinate offset hack.
//
// Reuse permitted under the MIT license.
//
// Seed hack added by @aft.
// Original shader: https://github.com/stegu/webgl-noise/blob/master/src/classicnoise2D.glsl
// Thank you Stefan Gustavson for all the work you have done.

#define OCTAVES 5

#if (OCTAVES > 1)
#define NOISE getnoise_fbm
#else
#define NOISE getnoise_single
#endif

varying vec3 v_vPosition;

uniform vec2 u_resolution;
uniform float u_seed;
uniform float u_persistence; // .3
uniform float u_freq; // 16.
uniform float u_scale; // 1.
uniform float u_xoffset; // 0.
uniform float u_yoffset; // 0.

// Original code starts here

//
// GLSL textureless classic 2D noise "cnoise",
// with an RSL-style periodic variant "pnoise".
// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
// Version: 2011-08-22
//
// Many thanks to Ian McEwan of Ashima Arts for the
// ideas for permutation and gradient selection.
//
// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/stegu/webgl-noise
//
// webgl-noise LICENSE (https://github.com/stegu/webgl-noise/blob/master/LICENSE):
//
// Copyright (C) 2011 by Ashima Arts (Simplex noise)
// Copyright (C) 2011-2016 by Stefan Gustavson (Classic noise and others)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
  return mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// Classic Perlin noise
float cnoise(vec2 P) {
  P += mod(u_seed * vec2(12.9898, 78.233), 289.0); // seed addition by shifting pos.

  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0;
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));

  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

// Original code ends here.
float getnoise_single(float persistence, float freq, vec2 coords) {
  float sum = cnoise(coords * freq);
  return sum * .5 + .5;
}

float getnoise_fbm(float persistence, float freq, vec2 coords) {
  float amp = 1.;
  float maxamp = 0.;
  float sum = 0.;
  for (int i = 0; i < OCTAVES; ++i) {
    sum += amp * cnoise(coords * freq);
    freq *= 2.1;
    maxamp += amp;
    amp *= persistence;
  }
  return (sum / maxamp) * .5 + .5;
}

void main() {
  vec2 p = vec2(v_vPosition.xy / u_resolution.x * u_scale);
  
  vec2 offset = vec2(u_xoffset, u_yoffset) / u_resolution.x * u_scale;
  p += offset;
  
  float value = NOISE(u_persistence, u_freq, p);
  gl_FragColor = vec4(vec3(value), 1.0);
}
