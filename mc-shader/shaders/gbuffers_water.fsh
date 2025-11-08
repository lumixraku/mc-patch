#version 120

// Water pass — force a Maldives-like lime/turquoise tint

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal; // from vsh (eye-space)
varying vec3 vEyePos; // from vsh (eye-space)

uniform sampler2D texture;
uniform int isEyeInWater; // 0 = air, 1 = water

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;

    // Softer, less-saturated Maldives turquoise (stable color)
    const vec3 limeTurquoise = vec3(0.28, 0.67, 0.52);

    // Do NOT use source luma — that causes visible, time-varying squares
    // from the animated vanilla water texture. Instead, bias toward a
    // stable color so the surface looks clean and calm.
    const float STRENGTH = 0.85; // keep texture hint, but muted
    vec3 tinted = mix(albedo.rgb, limeTurquoise, STRENGTH);
    
    // Slight saturation reduction to avoid neon
    float lum = dot(tinted, vec3(0.2126, 0.7152, 0.0722));
    tinted = mix(vec3(lum), tinted, 0.75);
    // Slight overall dim to avoid over-bright water in sunlight
    tinted *= 0.90;
    albedo.rgb = clamp(tinted, 0.0, 1.0);

    // Angle-aware surface opacity (simple Fresnel-like):
    // More opaque at grazing angles when viewed from air; keep default underwater.
    if (isEyeInWater == 0) {
        vec3 N = normalize(vNormal);
        vec3 V = normalize(-vEyePos);
        float cosNV = clamp(dot(N, V), 0.0, 1.0);
        float fresnel = pow(1.0 - cosNV, 3.0); // 0 at head-on, 1 at grazing
        // Base raise even at head-on; stronger at grazing
        float targetAlpha = mix(0.82, 0.95, fresnel);
        albedo.a = max(albedo.a, targetAlpha);
    }

    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
