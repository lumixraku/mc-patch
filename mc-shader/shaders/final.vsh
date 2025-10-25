#version 120

void main() {
    // 使用固定功能管线的纹理坐标通道，确保与 Iris/OptiFine 的全屏四边形一致
    gl_Position = ftransform();
    gl_TexCoord[0] = gl_MultiTexCoord0;
}
