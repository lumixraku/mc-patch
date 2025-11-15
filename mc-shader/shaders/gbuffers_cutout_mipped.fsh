#version 120

varying vec2 texcoord;
varying vec4 color;
varying float vBlockId;

uniform sampler2D texture;

const int BLOCK_EMISSIVE_SOLID = 1200;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;
    vec3 baseColor = albedo.rgb;
    if (albedo.a < 0.1) discard;
    albedo.a = 1.0; // make surviving fragments fully opaque

    int blockId = int(vBlockId + 0.5);
    if (blockId == BLOCK_EMISSIVE_SOLID) {
        const float EMISSIVE_STRENGTH = 0.8;
        albedo.rgb = mix(albedo.rgb, baseColor, EMISSIVE_STRENGTH);
    }

    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
