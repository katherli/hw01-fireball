#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color;
uniform float u_Time;
uniform vec4 u_CamPos;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_YOffset;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

#define SCLERA_R 0.1
#define OUTLINE 0.10
#define IRIS_R 0.03
#define BTW_EYES_DIST 0.3

#define MOUTH_WIDTH 0.3
#define MOUTH_HEIGHT 0.1
#define MOUTH_Y -0.2
#define MOUTH_OUTLINE 0.07

//from lab 1
float bias(float t, float b) {
    return (t / ((((1.0 / b) - 2.0) * (1.0 - t)) + 1.0));
}

float triangle_wave(float x, float freq, float amplitude) {
    return abs(mod(x * freq, amplitude) - (0.5 * amplitude));
}

float noise2D(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 269.5))) * 43758.5453);
}

float interpNoise2D(float x, float y) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);

    float v1 = noise2D(vec2(intX, intY));
    float v2 = noise2D(vec2(intX + 1, intY));
    float v3 = noise2D(vec2(intX, intY + 1));
    float v4 = noise2D(vec2(intX + 1, intY + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}

float fbm(float x, float y, float frequency, float amplitude, int octaves) {
    float total = 0.0;
    float persistence = 0.5f;
    float freq = frequency;
    float amp = amplitude;
    for (int i = 0; i < octaves; i++) {
        total += interpNoise2D(x * freq, y * freq) * amp;
        freq *= 2.0f;
        amp *= persistence;
    }
    return total;
}

float getBlinkScale() {
    // Vary blink timing with fbm
    float frequency = 0.15; 
    float amplitude = 0.2;
    int octaves = 2;
    
    float noiseValue = fbm(u_Time * 0.15, u_Time * 0.1, frequency, amplitude, octaves);

    float blinkFrequency = 0.15 + noiseValue * 0.15;

    return bias(triangle_wave(u_Time * blinkFrequency, 0.9, 2.0), 0.95);
}

float outline(vec4 fragPos) {
    vec4 leftEyeCenter = vec4(-BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0); 
    vec4 rightEyeCenter = vec4(BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0);

    if (fs_Nor.z < 0.0) {
        return 0.0;
    }

    float blinkScale = getBlinkScale();

    float leftEyeDist = length(vec2((fragPos.x - leftEyeCenter.x) / SCLERA_R, 
                                    (fragPos.y - leftEyeCenter.y) / (SCLERA_R * blinkScale)));
    float rightEyeDist = length(vec2((fragPos.x - rightEyeCenter.x) / SCLERA_R, 
                                     (fragPos.y - rightEyeCenter.y) / (SCLERA_R * blinkScale)));

    float leftOutline = smoothstep(0.005, 0.0, leftEyeDist - (1.0 + OUTLINE));
    float rightOutline = smoothstep(0.005, 0.0, rightEyeDist - (1.0 + OUTLINE));

    return leftOutline + rightOutline;
}

float sclera(vec4 fragPos) {
    vec4 leftEyeCenter = vec4(-BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0); 
    vec4 rightEyeCenter = vec4(BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0);

    if (fs_Nor.z < 0.0) {
        return 0.0;
    }

    float blinkScale = getBlinkScale();

    float leftIrisDist = length(vec2((fragPos.x - leftEyeCenter.x) / SCLERA_R, 
                                     (fragPos.y - leftEyeCenter.y) / (SCLERA_R * blinkScale)));
    float rightIrisDist = length(vec2((fragPos.x - rightEyeCenter.x) / SCLERA_R, 
                                      (fragPos.y - rightEyeCenter.y) / (SCLERA_R * blinkScale)));

    float leftIris = smoothstep(0.005, 0.0, leftIrisDist - 1.0);
    float rightIris = smoothstep(0.005, 0.0, rightIrisDist - 1.0);

    return leftIris + rightIris;
}

float iris(vec4 fragPos) {
    vec4 leftEyeCenter = vec4(-BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0); 
    vec4 rightEyeCenter = vec4(BTW_EYES_DIST, 0.1 + fs_YOffset, 1.0, 1.0);

    if (fs_Nor.z < 0.0) {
        return 0.0;
    }

    float blinkScale = getBlinkScale();

    float leftIrisDist = length(vec2((fragPos.x - leftEyeCenter.x) / IRIS_R, 
                                     (fragPos.y - leftEyeCenter.y) / (IRIS_R * blinkScale)));
    float rightIrisDist = length(vec2((fragPos.x - rightEyeCenter.x) / IRIS_R, 
                                      (fragPos.y - rightEyeCenter.y) / (IRIS_R * blinkScale)));

    float leftIris = smoothstep(0.005, 0.0, leftIrisDist - 1.0);
    float rightIris = smoothstep(0.005, 0.0, rightIrisDist - 1.0);

    return leftIris + rightIris;
}

float mouthOutline(vec4 fragPos) {
    vec4 mouthCenter = vec4(0.0, MOUTH_Y + fs_YOffset, 1.0, 1.0);

    if (fs_Nor.z < 0.0) {
        return 0.0;
    }

    float sineWave = 0.015 * sin(10.0 * (0.1 * -u_Time + fragPos.x));
    float mouthDist = length(vec2(fragPos.x / MOUTH_WIDTH, (fragPos.y - mouthCenter.y - sineWave) / MOUTH_HEIGHT));

    return smoothstep(0.005, 0.0, mouthDist - (1.0 + MOUTH_OUTLINE));
}

float mouthMask(vec4 fragPos) {
    vec4 mouthCenter = vec4(0.0, MOUTH_Y + fs_YOffset, 1.0, 1.0);

    if (fs_Nor.z < 0.0) {
        return 0.0; 
    }

    float sineWave = 0.015 * sin(10.0 * (0.1 * -u_Time + fragPos.x));
    float mouthDist = length(vec2(fragPos.x / MOUTH_WIDTH, (fragPos.y - mouthCenter.y - sineWave) / MOUTH_HEIGHT));

    return smoothstep(0.005, 0.0, mouthDist - 1.0);
}

void main() {
    vec4 glowColor = vec4(u_Color.x, u_Color.y + 0.6, u_Color.z, 1.0);
    vec4 center = vec4(0.0, 0.0, 0.0, 1.0);
    float intensity = 3.5; 

    // Distance of the fragment from the center of the sphere
    float distanceFromCenter = length(fs_Pos.xyz - center.xyz);
    
    float radius = 1.0 + 0.2 * bias(sin(u_Time * 0.35), 0.1);           
    float glowFalloff = smoothstep(radius, radius * 1.5, distanceFromCenter);

    // Calculate the glow intensity based on distance from the center
    float glow = (1.0 - glowFalloff) * intensity * 0.5;

    vec4 baseColor = u_Color;
    glowColor = vec4(glowColor.r + 0.2 * cos(u_Time * 0.3), glowColor.g + 0.1 * cos(u_Time * 0.5), glowColor.b, 1.0);
    glowColor = mix(glowColor * glow, baseColor, 0.6);
    vec4 finalColor = baseColor + glowColor;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.1, 1.0);

    float ambientTerm = 0.25;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute the eye/mouth masks
    float outlineMask = outline(fs_Pos);
    float scleraMask = sclera(fs_Pos);
    float irisMask = iris(fs_Pos);
    float mouthOutlineMask = mouthOutline(fs_Pos);
    float mouthMaskValue = mouthMask(fs_Pos);

    vec4 faceColor = finalColor;

    if (outlineMask > 0.0) {
        faceColor.rgb = vec3(0.0);
    }
    if (scleraMask > 0.0) {
        faceColor.rgb = vec3(1.0);
    }
    if (irisMask > 0.0) {
        faceColor.rgb = vec3(0.0);
    }

    if (mouthOutlineMask > 0.0) {
        faceColor.rgb = vec3(0.0);
    }
    if (mouthMaskValue > 0.0) {
        faceColor.rgb = u_Color.xyz;
    }

    out_Col = min(vec4(faceColor.rgb * lightIntensity, 1.0), vec4(1.0));

    // Toon shading for studio ghibli effect
    if (outlineMask == 0.0 && scleraMask == 0.0 && irisMask == 0.0 && mouthOutlineMask == 0.0 && mouthMaskValue == 0.0) {
        vec4 camDir = u_CamPos - fs_Pos;
        float d = dot(fs_Nor, normalize(camDir));

        if(d > 0.8) {
            out_Col += vec4(u_Color.x - 0.4, u_Color.y + 0.4, 0.0, 1.0f);
        }
    }
}