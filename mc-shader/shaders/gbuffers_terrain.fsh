#version 150

in vec2 texcoord;
in vec4 color;
out vec4 fragColor;

// Base terrain albedo
uniform sampler2D texture;

void main() {
    vec4 albedo = texture(texture, texcoord) * color;

    // Alpha test for cutout blocks (leaves, plants, etc.)
    if (albedo.a < 0.1) discard;

    fragColor = albedo;
}

/* DRAWBUFFERS:0 */

