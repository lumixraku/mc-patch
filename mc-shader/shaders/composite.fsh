#version 150

in vec2 texcoord;
out vec4 fragColor;

// Primary scene color buffer (Iris/OptiFine)
uniform sampler2D colortex0; // common in many versions
uniform sampler2D gcolor;    // some packs/versions use this name

// Toggle: 0=use colortex0, 1=use gcolor
#ifndef USE_GCOLOR
#define USE_GCOLOR 0
#endif

void main() {
    // Force-test: solid red overlay
    // fragColor = vec4(1.0, 0.0, 0.0, 1.0);

#if USE_GCOLOR
    fragColor = texture(gcolor, texcoord);
#else
    fragColor = texture(colortex0, texcoord);
#endif
}
