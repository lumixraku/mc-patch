#version 120

void main() {
    // 固定功能管线传参：主纹理与光照贴图坐标、顶点色
    gl_Position     = ftransform();
    gl_TexCoord[0]  = gl_MultiTexCoord0; // 主纹理
    gl_TexCoord[1]  = gl_MultiTexCoord1; // 光照贴图（亮度）
    gl_FrontColor   = gl_Color;
}

