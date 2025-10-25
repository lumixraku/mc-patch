#version 120

varying vec2 texcoord;

void main() {
    // 全屏四边形的标准传参：位置与纹理坐标
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.st; // 直接使用通道0的ST坐标
}
