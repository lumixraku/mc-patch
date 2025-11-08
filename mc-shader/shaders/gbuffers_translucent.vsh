#version 120

varying vec2 texcoord;
varying vec4 color;
varying float vBlockId;

attribute vec4 mc_Entity; // .x carries block ID (via block.properties)

void main() {
    texcoord = (gl_MultiTexCoord0).xy;
    color = gl_Color;
    vBlockId = mc_Entity.x;
    gl_Position = ftransform();
}
