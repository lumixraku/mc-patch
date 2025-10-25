#version 120

varying vec2 texcoord0;
varying vec2 texcoord1;

void main() {
    // 传递主纹理与光照贴图坐标、顶点色
    gl_Position   = ftransform();
    texcoord0     = gl_MultiTexCoord0.st; // 主纹理
    texcoord1     = gl_MultiTexCoord1.st; // 光照贴图（亮度）
    gl_FrontColor = gl_Color;
}
 
