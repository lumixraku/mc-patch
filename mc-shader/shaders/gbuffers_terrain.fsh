#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal;
varying vec2 lmcoord; // sky/torch lightmap UV

// Base terrain albedo
uniform sampler2D texture;
uniform vec3 sunPosition; // sun/moon direction (view space)
uniform vec3 upPosition;  // world up (view space)

// Map vanilla lightmap UVs to a simple scalar [0..1]
float envLightFactor(vec2 lm) {
    float sky = clamp(lm.t, 0.0, 1.0);
    float torch = clamp(lm.s, 0.0, 1.0);
    float torchBoost = torch * torch; // stronger close light
    return clamp(max(sky, torchBoost), 0.0, 1.0);
}

vec3 applyLighting(vec3 base, vec3 normal, float envL) {
    vec3 N = normalize(normal);
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir  = normalize(upPosition);
    float sunUp = dot(sunDir, upDir);          // >0 day, <0 night; view independent
    float day    = clamp(sunUp, 0.0, 1.0);
    float moon   = clamp(-sunUp, 0.0, 1.0);
    vec3 L = (sunUp >= 0.0) ? sunDir : -sunDir; // use the light that is above horizon

    // Half-Lambert / wrap diffuse to avoid very dark side faces
    float wrap = mix(0.05, 0.35, day); // more wrap at midday
    float ndl = max((dot(N, L) + wrap) / (1.0 + wrap), 0.0);

    // Stronger ambient outdoors so backfaces aren't too dark
    float ambient = mix(0.10, 0.55, envL);     // caves ~0.10, outdoors ~0.55
    float diffuseScale = day * 1.0 + moon * 0.06; // moon much weaker
    float lit = ambient + ndl * 0.7 * diffuseScale;
    return clamp(base * lit, 0.0, 1.0);
}

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;

    // Alpha test for cutout blocks (leaves, plants, etc.)
    if (albedo.a < 0.1) discard;
    albedo.a = 1.0; // surviving fragments should be opaque in terrain pass

    float envL = envLightFactor(lmcoord);
    albedo.rgb = applyLighting(albedo.rgb, vNormal, envL);
    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
