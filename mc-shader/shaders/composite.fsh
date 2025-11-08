#version 120

varying vec2 texcoord;

// Primary scene color buffer (Iris/OptiFine)
uniform sampler2D colortex0; // some versions
uniform sampler2D gcolor;    // common in others (default)
uniform int isEyeInWater;    // 0=air, 1=water

// Toggle: 0=use colortex0, 1=use gcolor
#ifndef USE_GCOLOR
#define USE_GCOLOR 1
#endif

void main() {
    // Force-test: solid red overlay
    // gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);

#if USE_GCOLOR
    vec4 c = texture2D(gcolor, texcoord);
#else
    vec4 c = texture2D(colortex0, texcoord);
#endif

    // Underwater tint: match surface tone but keep it subtle
    if (isEyeInWater == 1) {
        const vec3 limeTurquoise = vec3(0.30, 0.78, 0.55);
        // Very gentle blend; also slightly dim to avoid neon look
        const float STRENGTH = 0.12; // tweak 0.08..0.20 to taste
        c.rgb = mix(c.rgb, limeTurquoise, STRENGTH) * 0.96;
    }

    gl_FragColor = c;
}
