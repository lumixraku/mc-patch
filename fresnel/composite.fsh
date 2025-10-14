#version 120

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D gaux1;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;    // ← 添加这个
uniform mat4 gbufferModelViewInverse;     // ← 添加这个
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform vec2 pixelSize;

varying vec2 texcoord;

// Fresnel函数实现
float fresnel(vec3 viewDir, vec3 normal, float power) {
    float facing = dot(normalize(viewDir), normalize(normal));
    return pow(1.0 - abs(facing), power);
}

// 生成水面法线（波浪效果）
vec3 getWaterNormal(vec2 coord) {
    float time = frameTimeCounter;

    vec2 wave1 = coord * 8.0 + vec2(time * 0.1, time * 0.05);
    vec2 wave2 = coord * 12.0 + vec2(-time * 0.08, time * 0.12);

    float heightL = sin((wave1.x - 0.01)) * cos(wave1.y) * 0.02 +
                   sin((wave2.x - 0.01)) * cos(wave2.y) * 0.015;
    float heightR = sin((wave1.x + 0.01)) * cos(wave1.y) * 0.02 +
                   sin((wave2.x + 0.01)) * cos(wave2.y) * 0.015;
    float heightD = sin(wave1.x) * cos((wave1.y - 0.01)) * 0.02 +
                   sin(wave2.x) * cos((wave2.y - 0.01)) * 0.015;
    float heightU = sin(wave1.x) * cos((wave1.y + 0.01)) * 0.02 +
                   sin(wave2.x) * cos((wave2.y + 0.01)) * 0.015;

    vec3 normal = normalize(vec3(
        (heightL - heightR) * 50.0,
        1.0,
        (heightD - heightU) * 50.0
    ));

    return normal;
}

// ✅ 修正：正确的坐标重构
vec3 reconstructWorldPosition(vec2 screenUV, float depth) {
    // 1. 屏幕坐标 → NDC坐标
    vec4 ndcPos = vec4(screenUV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);

    // 2. NDC坐标 → 视图坐标（使用逆投影矩阵）
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= viewPos.w;  // 透视除法

    // 3. 视图坐标 → 世界坐标（使用逆模型视图矩阵）
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    return worldPos.xyz;
}

// ✅ 修正：屏幕空间反射UV计算
vec2 getReflectionUV(vec3 worldPos, vec3 normal, vec3 viewDir) {
    // 计算反射方向
    vec3 reflectDir = reflect(viewDir, normal);  // 注意：不需要负号

    // 反射射线终点
    vec3 reflectEndWorld = worldPos + reflectDir * 10.0;  // 延伸10单位

    // 世界坐标 → 视图坐标
    vec4 reflectViewPos = gbufferModelView * vec4(reflectEndWorld, 1.0);

    // 视图坐标 → 裁剪坐标
    vec4 reflectClipPos = gbufferProjection * reflectViewPos;

    // 透视除法 + NDC → 屏幕坐标
    vec2 reflectUV = (reflectClipPos.xy / reflectClipPos.w) * 0.5 + 0.5;

    // 添加波浪扭曲
    vec2 distortion = normal.xz * 0.02;  // 减小扭曲强度
    reflectUV += distortion;

    return reflectUV;
}

// 检测是否为水面
bool isWater(vec2 coord) {
    float depth = texture2D(depthtex0, coord).r;
    vec3 color = texture2D(colortex0, coord).rgb;

    float blueness = color.b - (color.r + color.g) * 0.5;
    return depth < 0.999 && blueness > 0.1;
}

// 辅助函数：线性化深度
float linearizeDepth(float depth) {
    float near = 0.1;
    float far = 1000.0;
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

void main() {
    vec3 sceneColor = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    if (!isWater(texcoord)) {
        gl_FragColor = vec4(sceneColor, 1.0);
        return;
    }

    // === ✅ 修正后的水面反射计算 ===

    // 重构世界坐标（使用正确的方法）
    vec3 worldPos = reconstructWorldPosition(texcoord, depth);

    // 计算视线方向（从摄像机指向像素）
    vec3 viewDir = normalize(worldPos - cameraPosition);

    // 获取水面法线
    vec3 waterNormal = getWaterNormal(texcoord);

    // 计算Fresnel系数
    float fresnelTerm = fresnel(viewDir, waterNormal, 2.0);

    // 获取反射UV
    vec2 reflectUV = getReflectionUV(worldPos, waterNormal, viewDir);

    // 读取反射内容
    vec3 reflectedColor = vec3(0.5, 0.7, 1.0);
    if (reflectUV.x >= 0.0 && reflectUV.x <= 1.0 &&
        reflectUV.y >= 0.0 && reflectUV.y <= 1.0) {
        reflectedColor = texture2D(colortex0, reflectUV).rgb;
    }

    // 水面基础颜色
    vec3 waterColor = vec3(0.1, 0.3, 0.6);

    // 应用Fresnel混合
    vec3 finalColor = mix(waterColor, reflectedColor, fresnelTerm * 0.8);

    // 添加深度衰减
    float waterDepth = linearizeDepth(depth) / 100.0;
    finalColor = mix(finalColor, waterColor, clamp(waterDepth, 0.0, 0.8));

    gl_FragColor = vec4(finalColor, 1.0);
}