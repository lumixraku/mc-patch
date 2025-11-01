#version 120

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;
    // No discard: keep alpha for glass/water-like materials
    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
