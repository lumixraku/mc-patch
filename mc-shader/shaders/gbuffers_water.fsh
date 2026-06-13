#version 120

// Water pass — calm turquoise water with a Fresnel sky reflection:
// transparent looking straight down (near water), mirror-like at grazing
// angles (distant water). The reflection samples the same procedural sky
// as gbuffers_skybasic, so the water tracks the day/night/sunset sky.

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal; // eye-space
varying vec3 vEyePos; // eye-space
varying float vBlockId;

uniform sampler2D texture;
uniform int isEyeInWater; // 0 = air, 1 = water
uniform vec3 sunPosition; // eye-space
uniform vec3 upPosition;  // eye-space

// Procedural sky color for an eye-space view direction. Mirrors
// gbuffers_skybasic.fsh (day/night gradient + multi-band sunset wash) so the
// reflection matches the sky. Keep the two in sync.
vec3 skyColor(vec3 dir, vec3 upDir, vec3 sunDir, float sunUp) {
    float h = dot(dir, upDir);
    float dayF = smoothstep(-0.06, 0.16, sunUp);
    float t = clamp((h + 0.05) / 1.05, 0.0, 1.0);
    vec3 day   = mix(vec3(0.835, 0.910, 0.970), vec3(0.247, 0.561, 0.851), pow(t, 0.7));
    vec3 night = mix(vec3(0.050, 0.070, 0.140), vec3(0.012, 0.027, 0.078), pow(t, 0.6));
    vec3 col = mix(night, day, dayF);

    float duskF = clamp(1.0 - abs(sunUp) / 0.30, 0.0, 1.0);
    float sunFacing = max(dot(dir, sunDir), 0.0);
    vec3 sunset = vec3(0.55, 0.16, 0.08);
    sunset = mix(sunset, vec3(1.00, 0.55, 0.18), smoothstep(-0.25, 0.02, h));
    sunset = mix(sunset, vec3(0.95, 0.42, 0.30), smoothstep(0.00, 0.35, h));
    sunset = mix(sunset, vec3(0.62, 0.22, 0.42), smoothstep(0.25, 0.70, h));
    sunset = mix(sunset, vec3(0.24, 0.10, 0.32), smoothstep(0.55, 1.05, h));
    float fill = duskF * (0.72 + 0.28 * pow(sunFacing, 2.0));
    col = mix(col, sunset, clamp(fill, 0.0, 1.0) * 0.92);
    col += vec3(1.00, 0.42, 0.12) * duskF * pow(sunFacing, 3.0)
         * pow(max(1.0 - abs(h), 0.0), 5.0) * 0.45;
    return col;
}

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;

    // Only shade actual water blocks; pass anything else through untouched.
    const int BLOCK_WATER = 1000;
    int blockId = int(vBlockId + 0.5);
    bool isClassicWater = (blockId == 8 || blockId == 9);
    if (!(blockId == BLOCK_WATER || isClassicWater)) {
        gl_FragData[0] = albedo;
        return;
    }

    // Stable turquoise "see-through" color. Biased toward a fixed tint (not
    // the animated vanilla texture's luma) so the surface stays clean.
    const vec3 limeTurquoise = vec3(0.28, 0.67, 0.52);
    vec3 tinted = mix(albedo.rgb, limeTurquoise, 0.85);
    float lum = dot(tinted, vec3(0.2126, 0.7152, 0.0722));
    tinted = mix(vec3(lum), tinted, 0.75) * 0.90;
    vec3 waterCol = clamp(tinted, 0.0, 1.0);

    if (isEyeInWater == 0) {
        vec3 N = normalize(vNormal);
        vec3 I = normalize(vEyePos); // eye -> surface
        vec3 V = -I;                 // surface -> eye
        float cosNV = clamp(dot(N, V), 0.0, 1.0);

        // Schlick Fresnel with water's F0 (~0.02): ~0 looking straight down
        // (near / transparent), rising to ~1 at grazing angles (far / mirror).
        const float F0 = 0.02;
        float fres = F0 + (1.0 - F0) * pow(1.0 - cosNV, 5.0);

        // Reflect the procedural sky off the (flat, calm) surface.
        vec3 upDir  = normalize(upPosition);
        vec3 sunDir = normalize(sunPosition);
        float sunUp = dot(sunDir, upDir);
        vec3 R = normalize(reflect(I, N));
        vec3 reflSky = skyColor(R, upDir, sunDir, sunUp);

        vec3 col = mix(waterCol, reflSky, fres);

        // Restrained mirrored sun glint (strongest at grazing / sunset).
        float rd = max(dot(R, sunDir), 0.0);
        float day = clamp(sunUp, 0.0, 1.0);
        col += vec3(1.0, 0.96, 0.86) * pow(rd, 200.0) * (0.4 + 0.6 * day) * (0.3 + 0.7 * fres);

        albedo.rgb = clamp(col, 0.0, 1.0);
        // Transparent up close (bottom shows through), opaque at grazing.
        albedo.a = clamp(mix(0.55, 0.93, fres), 0.0, 0.95);
    } else {
        // Underwater: just the tint, no sky reflection.
        albedo.rgb = waterCol;
    }

    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
