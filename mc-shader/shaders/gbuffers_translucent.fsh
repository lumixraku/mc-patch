#version 120

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;

    // Heuristic: water in vanilla is translucent and strongly blue/cyan-tinted.
    // We detect likely-water by blue dominance and sufficient alpha, then tint toward
    // a Maldives-like lime-green turquoise.
    float maxRG = max(albedo.r, albedo.g);
    bool blueDominant = (albedo.b > maxRG + 0.05);
    bool isTranslucent = (albedo.a > 0.15);

    if (blueDominant && isTranslucent) {
        // Target lime-turquoise color (Maldives vibe)
        const vec3 limeTurquoise = vec3(0.38, 0.95, 0.62);
        // Preserve perceived brightness while shifting hue
        float luma = dot(albedo.rgb, vec3(0.2126, 0.7152, 0.0722));
        vec3 target = normalize(limeTurquoise) * max(luma, 0.15);
        // Blend strength: 0.0=no change, 1.0=full lime
        const float STRENGTH = 0.75;
        albedo.rgb = mix(albedo.rgb, target, STRENGTH);
        // Slight boost to vibrance
        albedo.rgb = clamp(albedo.rgb * 1.05, 0.0, 1.0);
    }

    // No discard: keep alpha for glass/water-like materials
    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
