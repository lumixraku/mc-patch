#version 120

/* Procedural sky (ported from web-minecraft sky.js).
   The whole sky is computed analytically from the view direction's altitude
   `h`, NOT from the vanilla per-vertex color. Minecraft draws the sky as two
   separate meshes (the upper dome and the lower void/fog plane) whose vertex
   colors differ sharply, so reusing gl_Color leaves a hard horizontal seam at
   the horizon. Building the gradient ourselves removes that seam entirely. */

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

void main() {
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir  = normalize(upPosition);
    float sunUp = dot(sunDir, upDir);    // sun elevation: >0 day, <0 night

    // Per-pixel view ray altitude (h: -1 nadir .. 0 horizon .. 1 zenith).
    vec4 clip = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0, 1.0) * 2.0 - 1.0;
    vec4 vpos = gbufferProjectionInverse * clip;
    vec3 viewDir = normalize(vpos.xyz);
    float h = dot(viewDir, upDir);

    // --- Day / night vertical gradient (driven by sun elevation) ---
    float dayF = smoothstep(-0.06, 0.16, sunUp);
    vec3 dayTop   = vec3(0.247, 0.561, 0.851);
    vec3 dayHor   = vec3(0.835, 0.910, 0.970);
    vec3 nightTop = vec3(0.012, 0.027, 0.078);
    vec3 nightHor = vec3(0.050, 0.070, 0.140);
    float t = clamp((h + 0.05) / 1.05, 0.0, 1.0);
    vec3 day   = mix(dayHor, dayTop, pow(t, 0.7));
    vec3 night = mix(nightHor, nightTop, pow(t, 0.6));
    vec3 col = mix(night, day, dayF);

    // --- Dusk / sunset wash ---
    // Brightest warm band straddles the horizon (h=0) and fades smoothly both
    // downward (to ember) and upward; warm->cool handoff is spread over a wide
    // h range with the cool tones pushed up toward the zenith. Peaks when the
    // sun sits on the horizon, gone by ~0.3 elevation.
    float duskF = clamp(1.0 - abs(sunUp) / 0.30, 0.0, 1.0);
    float sunFacing = max(dot(viewDir, sunDir), 0.0);

    vec3 duskGlow  = vec3(1.00, 0.42, 0.12);
    vec3 duskEmber = vec3(0.55, 0.16, 0.08);  // below horizon
    vec3 duskAmb   = vec3(1.00, 0.55, 0.18);  // brightest, at the horizon
    vec3 duskCoral = vec3(0.95, 0.42, 0.30);  // low sky
    vec3 duskMag   = vec3(0.62, 0.22, 0.42);  // mid sky
    vec3 duskZen   = vec3(0.24, 0.10, 0.32);  // zenith
    vec3 sunset = duskEmber;
    sunset = mix(sunset, duskAmb,   smoothstep(-0.25, 0.02, h));
    sunset = mix(sunset, duskCoral, smoothstep(0.00, 0.35, h));
    sunset = mix(sunset, duskMag,   smoothstep(0.25, 0.70, h));
    sunset = mix(sunset, duskZen,   smoothstep(0.55, 1.05, h));

    // Fill the sky, a touch stronger toward the sun's side.
    float fill = duskF * (0.72 + 0.28 * pow(sunFacing, 2.0));
    col = mix(col, sunset, clamp(fill, 0.0, 1.0) * 0.92);
    // Warm glow hugging the horizon around the sun.
    col += duskGlow * duskF * pow(sunFacing, 3.0) * pow(max(1.0 - abs(h), 0.0), 5.0) * 0.45;

    gl_FragData[0] = vec4(col, 1.0);
}

/* DRAWBUFFERS:0 */
