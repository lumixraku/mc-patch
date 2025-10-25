#version 120

// Scene inputs
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

// Matrices
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

// Camera/time
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

// Misc
uniform float rainStrength;    // Provided by OptiFine/Iris

varying vec2 texcoord;

// Fresnel helper
float fresnel(vec3 viewDir, vec3 normal, float power) {
    float f = clamp(dot(normalize(viewDir), normalize(normal)), -1.0, 1.0);
    return pow(1.0 - abs(f), power);
}

// Gentle water normal from two scrolling waves
vec3 waterNormal(vec2 uv, float t) {
    vec2 w1 = uv * 8.0 + vec2(t * 0.10, t * 0.05);
    vec2 w2 = uv * 12.0 + vec2(-t * 0.08, t * 0.12);

    float hl = sin(w1.x - 0.01) * cos(w1.y) * 0.02 + sin(w2.x - 0.01) * cos(w2.y) * 0.015;
    float hr = sin(w1.x + 0.01) * cos(w1.y) * 0.02 + sin(w2.x + 0.01) * cos(w2.y) * 0.015;
    float hd = sin(w1.x) * cos(w1.y - 0.01) * 0.02 + sin(w2.x) * cos(w2.y - 0.01) * 0.015;
    float hu = sin(w1.x) * cos(w1.y + 0.01) * 0.02 + sin(w2.x) * cos(w2.y + 0.01) * 0.015;
    return normalize(vec3((hl - hr) * 50.0, 1.0, (hd - hu) * 50.0));
}

// Reconstruct world position from depth + screen uv
vec3 reconstructWorldPosition(vec2 uv, float depth) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * ndc;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    return worldPos.xyz;
}

// Project a world point back to screen uv
vec2 worldToUV(vec3 world) {
    vec4 viewPos = gbufferModelView * vec4(world, 1.0);
    vec4 clip = gbufferProjection * viewPos;
    vec2 ndc = clip.xy / clip.w;
    return ndc * 0.5 + 0.5;
}

// Approximate SSR sample for reflections
vec3 sampleReflection(vec3 worldPos, vec3 normal, vec3 viewDir, float dist, vec2 distort) {
    vec3 rdir = reflect(viewDir, normal);
    vec3 rpos = worldPos + rdir * dist;
    vec2 uv = worldToUV(rpos) + distort;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return texture2D(colortex0, clamp(uv, 0.0, 1.0)).rgb;
    return texture2D(colortex0, uv).rgb;
}

// Heuristic: identify sky by depth ≈ 1.0
bool isSky(float d) {
    return d >= 0.9999;
}

// Simple morning/evening glow based on a synthetic day cycle.
// If `sunAngle` is not available, we fall back to a loop using frameTimeCounter.
float dayPhase() {
    // 0..1 loop ~120s per day visualized (slow, demo friendly)
    return fract(frameTimeCounter / 120.0);
}

vec3 skyTint(vec2 uv) {
    float t = dayPhase();
    // Windows near sunrise (~0.23) and sunset (~0.73)
    float sunrise = exp(-pow((t - 0.23) / 0.08, 2.0));
    float sunset  = exp(-pow((t - 0.73) / 0.08, 2.0));
    float glow = clamp(sunrise + sunset, 0.0, 1.0);

    // Stronger near horizon (lower screen y)
    float horizon = smoothstep(0.0, 0.5, 1.0 - uv.y);

    vec3 baseSky = vec3(0.5, 0.7, 1.0);
    vec3 warm = vec3(1.0, 0.55, 0.25);
    return mix(baseSky, warm, glow * horizon * 0.7);
}

// Flatness heuristic for puddles: small depth gradient => flatter surface
float flatMask(vec2 uv) {
    float d = texture2D(depthtex0, uv).r;
    float dx = abs(d - texture2D(depthtex0, uv + vec2(1.0/1920.0, 0.0)).r);
    float dy = abs(d - texture2D(depthtex0, uv + vec2(0.0, 1.0/1080.0)).r);
    float g = dx + dy;
    return 1.0 - clamp(g * 60.0, 0.0, 1.0);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    // Sky tint
    if (isSky(depth)) {
        vec3 tinted = skyTint(texcoord);
        gl_FragColor = vec4(tinted, 1.0);
        return;
    }

    // Water fresnel reflection (screen-space)
    // Heuristic water detection: moderate depth and bluish/greenish base
    vec3 base = color;
    float blueness = base.b - (base.r + base.g) * 0.45;
    float greenness = base.g - (base.r + base.b) * 0.35;
    bool looksWater = (blueness > 0.05 || greenness > 0.05) && depth < 0.999;

    if (looksWater) {
        vec3 worldPos = reconstructWorldPosition(texcoord, depth);
        vec3 viewDir = normalize(worldPos - cameraPosition);
        vec3 n = waterNormal(texcoord, frameTimeCounter);

        float f = fresnel(viewDir, n, 2.0);
        vec2 distort = n.xz * 0.02;
        vec3 refl = sampleReflection(worldPos, n, viewDir, 8.0, distort);

        // Emerald tint to stay consistent with gbuffers_water
        vec3 waterColor = vec3(0.0, 0.8, 0.35);
        vec3 mixed = mix(waterColor, refl, f * 0.8);
        color = mixed;
    }

    // Rain puddles: glossy boost and faint reflection on flat ground
    if (rainStrength > 0.01) {
        float flatness = flatMask(texcoord);
        float wet = rainStrength * flatness;

        vec3 worldPos = reconstructWorldPosition(texcoord, depth);
        vec3 viewDir = normalize(worldPos - cameraPosition);
        // Assume mostly upward-facing for puddles; bias normal toward up
        vec3 upN = normalize(mix(vec3(0.0, 1.0, 0.0), waterNormal(texcoord * 0.5, frameTimeCounter), 0.15));
        vec3 refl = sampleReflection(worldPos, upN, viewDir, 4.0, upN.xz * 0.01);

        float gloss = fresnel(viewDir, upN, 3.0) * 0.6;
        color = mix(color, refl, gloss * wet * 0.35);
        // Slight darkening to imply wetness
        color *= 1.0 - wet * 0.08;
    }

    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
