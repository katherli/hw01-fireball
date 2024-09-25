#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ViewProj;
uniform float u_Time;
uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.
uniform float u_Intensity;
uniform float u_TimeOffset;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Pos; 
out vec4 fs_Col;
out float fs_YOffset;

const vec4 lightPos = vec4(5, 5, 3, 1);

//noise functions are from cis 460 lecture slides, toolbox functions are from 566 slides

float sawtooth_wave(float x, float freq, float amplitude) {
    return (x * freq - floor(x * freq)) * amplitude;
}

vec3 random3(vec3 p) {
    return fract(sin(vec3(
        dot(p, vec3(127.1, 311.7, 191.999)),
        dot(p, vec3(269.5, 183.3, 569.21)),
        dot(p, vec3(420.6, 631.2, 780.2))
    )) * 43758.5453);
}

vec3 pow3D(vec3 vec, float exp) {
    return vec3(
        pow(vec.x, exp),
        pow(vec.y, exp),
        pow(vec.z, exp)
    );
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.f) - 6.f * pow3D(t2, 5.f) + 15.f * pow3D(t2, 4.f) - 10.f * pow3D(t2, 3.f);
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2. - vec3(1., 1., 1.);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for(int dz = 0; dz <= 1; ++dz) {
				surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
			}
		}
	}
	return surfletSum;
}

float worleyNoise(vec3 uv) {
    uv *= 1.7; // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec3 uvInt = floor(uv);
    vec3 uvFract = fract(uv);
    float minDist = 1.0; // Minimum distance initialized to max.
    for(int z = -1; z <= 1; ++z) {
        for(int y = -1; y <= 1; ++y) {
            for(int x = -1; x <= 1; ++x) {
                vec3 neighbor = vec3(float(x), float(y), float(z)); // Direction in which neighbor cell lies
                vec3 point = random3(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec3 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

vec4 flameY(vec4 modelposition) {
    float flameT = u_Time * (0.07 * u_TimeOffset);

    //float perlinValue = 0.0;  //for testing
    float perlinValue = perlinNoise3D(modelposition.xyz + flameT);
    
    float worleyValue = u_Intensity * worleyNoise(modelposition.xyz + flameT);
    //float worleyValue = 0.0;  //for testing

    worleyValue = pow(worleyValue, 1.7);

    // Combine the noise values and apply the displacement
    float vertOffset = perlinValue + worleyValue;
    
    // Apply a larger vertical displacement for a more pronounced spike effect
    modelposition.y += vertOffset * 1.5; // Increase multiplier to make spikes more prominent

    return modelposition;
}

vec4 flame(vec4 modelposition) {
    if (modelposition.y >= 0.0) {
            vec4 flameY = flameY(modelposition);
            modelposition.y = mix(modelposition.y, flameY.y, modelposition.y);
    }   
    return modelposition;
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

// fbm to make it look like heat radiating across the surface
vec4 fbmSurface(vec4 position, vec4 normal) {
    float surfaceT = u_Time * (0.03 * u_TimeOffset);
    float fbmValue = fbm(position.x + surfaceT, position.z + surfaceT, 8.0, 0.02, 8);

    position.xyz += normal.xyz * fbmValue * 1.6;
    
    return position;
}

vec4 bodyShape(vec4 position) {

    // Top flame part
    position = flame(position);
    
    // Dome shape body
    float squashFactor = 1.0;
    
    if (vs_Pos.y > 0.0) {
        squashFactor = 1.0 - 0.3 * vs_Pos.y;
        position.x *= squashFactor;
        position.z *= squashFactor;
        position.y *= 0.9 + 0.1 * (1.0 - vs_Pos.y);
    }

    // Define the center positions of the arms in local space
    vec4 rightArmCenter = vec4(0.6, -0.5, 0.6, 1.0);
    vec4 leftArmCenter = vec4(-0.6, -0.5, 0.6, 1.0);
    
    float armWidth = 0.24;
    float armThickness = 0.8;

    // Calculate distance from arm centers
    float rightArmDist = length(position - rightArmCenter);
    float leftArmDist = length(position - leftArmCenter);
    
    if (rightArmDist < armWidth) {
        // Use smoothstep to round the displacement towards the tips
        float smoothFactor = smoothstep(0.0, 0.08, rightArmDist);
        float displacementFactor = (armWidth - rightArmDist) * 1.5 * smoothFactor;
        position.x += displacementFactor * armThickness * 0.2;
        position.y -= displacementFactor * armThickness * 2.0;
        position.z += displacementFactor;
    } else if (leftArmDist < armWidth) {
        float smoothFactor = smoothstep(0.0, 0.08, leftArmDist);
        float displacementFactor = (armWidth - leftArmDist) * 1.5 * smoothFactor;
        position.x -= displacementFactor * armThickness * 0.2;
        position.y -= displacementFactor * armThickness * 2.0;
        position.z += displacementFactor;
    } else {
        float sinT = u_Time * (0.2 * u_TimeOffset);
        position.x += (0.05f * sin((8.0 - u_Intensity) * (-sinT + position.y))); // Negative time so sine waves travel up
    }
    position.x *= 1.1 * (0.8 + u_Intensity * 0.2);
    position.y *= 0.9;
    position.z *= 0.8 + u_Intensity * 0.2;
    
    return position;
}

void main() {
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
                                                            
    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    
    // Deform main body
    modelposition = bodyShape(modelposition);
    
    modelposition = fbmSurface(modelposition, fs_Nor);

    float offsetT = u_Time * (0.09 * u_TimeOffset);
    fs_YOffset = sin(u_Time * 0.09) * 0.1;
    modelposition.y += sin(0.09 * u_Time) * 0.1;

    // Apply to model matrix to transform the vertex
    vec4 worldPos = u_Model * modelposition;

    fs_LightVec = lightPos - worldPos;  // Compute the direction in which the light source lies

    fs_Pos = worldPos;
    gl_Position = u_ViewProj * worldPos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}