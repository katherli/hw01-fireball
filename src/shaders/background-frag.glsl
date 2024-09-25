#version 300 es
precision highp float;

uniform vec2 u_Dimensions;

vec3 u_BrickColor = vec3(0.8, 0.3, 0.2);
vec3 u_MortarColor = vec3(1.0);

vec2 u_BrickSize = vec2(0.28, 0.18); 
vec2 u_BrickPct = vec2(0.95, 0.9);

in vec2 fs_Pos;
out vec4 out_Col;

void main() {
  vec2 uv = (fs_Pos + vec2(1.0)) * 0.5;

  vec2 scaledUV = uv / u_BrickSize;

  if (mod(floor(scaledUV.y), 2.0) == 1.0) {
    scaledUV.x += 0.5;
  }

  vec2 brickUV = fract(scaledUV);

  vec2 isBrick = step(brickUV, u_BrickPct);

  float isInBrick = isBrick.x * isBrick.y;

  vec3 color = mix(u_MortarColor, u_BrickColor, isInBrick);

  color *= 0.4;

  out_Col = vec4(color, 1.0);
}
