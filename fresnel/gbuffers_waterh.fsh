#version 120

uniform sampler2D texture;
uniform float frameTimeCounter;
varying vec2 texcoord;
varying vec3 worldPosition;
varying vec3 viewPosition;

void main() {
    // 渲染场景内容（树、建筑、玩家等）
    vec4 sceneColor = texture2D(texture, texcoord);

    // 如果不是水面，直接输出场景颜色
    if (sceneColor.a < 0.9) {
        gl_FragData[0] = sceneColor;  // 写入colortex0
        return;
    }

    // 水面的基础颜色
    vec3 waterColor = vec3(0.1, 0.3, 0.6);
    gl_FragData[0] = vec4(waterColor, 1.0);
}