#version 120

// Water pass — force a Maldives-like lime/turquoise tint

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;

    // Strong, bright lime-turquoise target
    const vec3 limeTurquoise = vec3(0.38, 0.95, 0.62);

    // Preserve perceived brightness while shifting hue
    float luma = dot(albedo.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 target = normalize(limeTurquoise) * max(luma, 0.18);

    // Blend toward target; keep translucency from the original alpha
    const float STRENGTH = 0.85; // increase for greener water
    albedo.rgb = mix(albedo.rgb, target, STRENGTH);
    albedo.rgb = clamp(albedo.rgb * 1.04, 0.0, 1.0); // slight vibrance

    gl_FragData[0] = albedo; // keep alpha for proper water blending
}

/* DRAWBUFFERS:0 */

