#version 120

uniform sampler2D colortex0;
varying vec2 texcoord;

void main() {
    // 直接输出原始颜色，不进行任何处理
    // gl_FragColor = texture2D(colortex0, texcoord);
    gl_FragColor = texture2D(colortex0, gl_TexCoord[0].st);
}

