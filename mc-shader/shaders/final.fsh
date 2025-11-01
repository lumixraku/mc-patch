#version 120

/* Final pass: keep default block colors (Chocapic-style). */

uniform sampler2D colortex0; // some versions
uniform sampler2D gcolor;    // common in others (default)
varying vec2 texcoord;       // from vsh

// Toggle: 0=use colortex0, 1=use gcolor
#ifndef USE_GCOLOR
#define USE_GCOLOR 1
#endif

void main() {
    // Forced test (yellow)
    // gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);

#if USE_GCOLOR
    gl_FragColor = texture2D(gcolor, texcoord);
#else
    gl_FragColor = texture2D(colortex0, texcoord);
#endif
}
