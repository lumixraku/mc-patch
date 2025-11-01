#version 120

varying vec2 texcoord;

// Primary scene color buffer (Iris/OptiFine)
uniform sampler2D colortex0; // some versions
uniform sampler2D gcolor;    // common in others (default)

// Toggle: 0=use colortex0, 1=use gcolor
#ifndef USE_GCOLOR
#define USE_GCOLOR 1
#endif

void main() {
    // Force-test: solid red overlay
    // gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);

#if USE_GCOLOR
    gl_FragColor = texture2D(gcolor, texcoord);
#else
    gl_FragColor = texture2D(colortex0, texcoord);
#endif
}
