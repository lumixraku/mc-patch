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

    // Underwater tint: light lime-green to match surface water
    if (isEyeInWater == 1) {
        const vec3 limeTurquoise = vec3(0.38, 0.95, 0.62);
        // Gentle blend so world remains readable
        const float STRENGTH = 0.20; // increase for a greener underwater
        float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
        vec3 target = normalize(limeTurquoise) * max(luma, 0.18);
        c.rgb = mix(c.rgb, target, STRENGTH);
    }

    gl_FragColor = c;
}
