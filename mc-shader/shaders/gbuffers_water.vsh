#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal; // eye-space normal
varying vec3 vEyePos; // eye-space position

void main() {
    texcoord = (gl_MultiTexCoord0).xy;
    color = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vEyePos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    gl_Position = ftransform();
}
