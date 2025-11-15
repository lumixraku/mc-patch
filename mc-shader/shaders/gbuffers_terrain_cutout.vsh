#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal;
varying vec2 lmcoord;
varying float vBlockId;

attribute vec4 mc_Entity;

void main() {
    texcoord = (gl_MultiTexCoord0).xy;
    color = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vBlockId = mc_Entity.x;
    gl_Position = ftransform();
}
