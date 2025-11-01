#version 120

varying vec2 texcoord;
varying vec4 color;

// Base albedo/texture from the game
uniform sampler2D texture;

void main() {
    // Toggle test color (commented by default)
    // gl_FragData[0] = vec4(1.0, 0.0, 0.0, 1.0);

    // Use the original material color (albedo), with vertex tint
    vec4 albedo = texture2D(texture, texcoord) * color;
    albedo.a = 1.0; // opaque in basic
    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
