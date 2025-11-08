#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal; // eye-space normal
varying vec3 vEyePos; // eye-space position
varying float vBlockId; // pass entity/block id

attribute vec4 mc_Entity; // provided by OptiFine/Iris

void main() {
    texcoord = (gl_MultiTexCoord0).xy;
    color = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vEyePos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vBlockId = mc_Entity.x;
    gl_Position = ftransform();
}
