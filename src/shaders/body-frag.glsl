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

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

#define SCLERA_R 0.1
#define OUTLINE 0.115
#define IRIS_R 0.03
#define BTW_EYES_DIST 0.3

vec4 leftEyeCenter = vec4(-BTW_EYES_DIST, 0.1, 1.0, 1.0);  // Adjust the z position to match the front of your flame object
vec4 rightEyeCenter = vec4(BTW_EYES_DIST, 0.1, 1.0, 1.0);

float outline(vec4 fragPos) {
    float leftOutline = smoothstep(0.005, 0.0, length(leftEyeCenter.xyz - fragPos.xyz) - OUTLINE);
    float rightOutline = smoothstep(0.005, 0.0, length(rightEyeCenter.xyz - fragPos.xyz) - OUTLINE);
    return leftOutline + rightOutline;
}

float sclera(vec4 fragPos) {
    float leftSclera = smoothstep(0.005, 0.0, length(leftEyeCenter.xyz - fragPos.xyz) - SCLERA_R);
    float rightSclera = smoothstep(0.005, 0.0, length(rightEyeCenter.xyz - fragPos.xyz) - SCLERA_R);
    return leftSclera + rightSclera;
}

// Function to compute the mask for the iris (dark center of the eye)
float iris(vec4 fragPos) {
    float leftIris = smoothstep(0.005, 0.0, length(leftEyeCenter.xyz - fragPos.xyz) - IRIS_R);
    float rightIris = smoothstep(0.005, 0.0, length(rightEyeCenter.xyz - fragPos.xyz) - IRIS_R);
    return leftIris + rightIris;
}

//from lab 1
float bias(float t, float b) {
    return (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
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

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute the eye masks
    float outlineMask = outline(fs_Pos);
    float scleraMask = sclera(fs_Pos);  // Sclera (white part)
    float irisMask = 1.0 - iris(fs_Pos);  // Iris (dark center)

    vec4 eyeColor = finalColor;

    if (outlineMask > 0.0) {
        eyeColor.rgb = vec3(0.0);
    }
    if (scleraMask > 0.0) {
        eyeColor.rgb = vec3(1.0);  // White sclera
    }
    if (irisMask < 1.0) {
        eyeColor.rgb = vec3(0.0);  // Dark iris
    }

    out_Col = min(vec4(eyeColor.rgb * lightIntensity, eyeColor.a), vec4(1.0));

    // Toon shading for studio ghibli effect
    vec4 camDir = u_CamPos - fs_Pos;
    float d = dot(fs_Nor, normalize(camDir));

    if(d > 0.8) {
        out_Col += vec4(u_Color.x - 0.4, u_Color.y + 0.4, 0.0, 1.0f);
    }
}