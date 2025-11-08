#version 120

// Particles pass. Make all particles invisible while the camera is underwater.

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;
uniform int isEyeInWater; // 0 = air, 1 = water, 2 = lava, 3 = powder snow

void main() {
    // Hide particles when underwater to remove purple squares/rectangles
    if (isEyeInWater == 1) {
        discard;
    }

    vec4 albedo = texture2D(texture, texcoord) * color;

    // Typical alpha test to avoid faint quads around small particle sprites
    if (albedo.a < 0.1) discard;

    gl_FragData[0] = albedo; // standard blended particle
}

/* DRAWBUFFERS:0 */

