#version 150

/*
 Final pass: keep default block colors.
 For forced test, uncomment the yellow override below.
*/

// Inputs provided by the pipeline (Iris/OptiFine):
uniform sampler2D colortex0; // main color buffer (many versions)
uniform sampler2D gcolor;    // alternative name in some versions
in vec2 texcoord;            // full-screen UV from vsh

// Toggle: 0=use colortex0, 1=use gcolor
#ifndef USE_GCOLOR
#define USE_GCOLOR 0
#endif

out vec4 fragColor;

void main() {
    // Forced test color (yellow):
    // fragColor = vec4(1.0, 1.0, 0.0, 1.0);

#if USE_GCOLOR
    fragColor = texture(gcolor, texcoord);
#else
    fragColor = texture(colortex0, texcoord);
#endif
}
