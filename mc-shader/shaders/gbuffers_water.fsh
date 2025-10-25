#version 120

// OptiFine/Iris 在 gbuffers 阶段提供的材质与光照贴图
uniform sampler2D texture;   // 方块/流体的主纹理
uniform sampler2D lightmap;  // 光照贴图（环境与直射光）
varying vec2 texcoord0;
varying vec2 texcoord1;

void main() {
    // 采样基础颜色（含顶点色调制），并应用光照贴图
    vec4 base = texture2D(texture,  texcoord0) * gl_Color;
    vec3 lm   = texture2D(lightmap, texcoord1).rgb;
    vec3 color = base.rgb * lm; // 简单光照影响

    // 马尔代夫海水的青绿色调（轻柔偏绿蓝），强度可按需调整
    const vec3 maldives = vec3(0.26, 0.88, 0.72);
    const float strength = 0.65; // 0.0=不变, 1.0=完全替换
    color = mix(color, maldives, strength);

    // 保留透明度以维持水的半透明效果
    gl_FragColor = vec4(color, base.a);
}
