#version 120

/* Simple brighter sky.
   By request: force a fixed azure sky color between time=3000..8000.
   Outside that window, use vanilla sky color scaled by day factor. */

varying vec4 vColor;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

void main() {
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir  = normalize(upPosition);
    float sunUp = dot(sunDir, upDir);    // >0 day, <0 night
    float day = clamp(sunUp, 0.0, 1.0);

    // Requested azure sky for daytime window (with soft time fade)
    const vec3 SKY_BLUE = vec3(0.40, 0.70, 1.00); // photo-like blue
    float t = float(worldTime);
    float timeIn = smoothstep(2800.0, 3000.0, t);
    float timeOut = 1.0 - smoothstep(8000.0, 8200.0, t);
    float azureWeight = clamp(timeIn * timeOut, 0.0, 1.0); // 0..1

    // View direction and altitude
    vec4 clip = vec4(gl_FragCoord.xy/vec2(viewWidth, viewHeight), 1.0, 1.0) * 2.0 - 1.0;
    vec4 vpos = gbufferProjectionInverse * clip;
    vec3 viewDir = normalize(vpos.xyz);
    float h = dot(viewDir, upDir);  // -1..1, 0 = horizon, 1 = zenith

    // Day blue base (azure window blended over vanilla sky)
    vec3 vanillaBright = clamp(vColor.rgb * mix(1.0, 1.20, day), 0.0, 1.0);
    vec3 dayBlue = mix(vanillaBright, SKY_BLUE, azureWeight);
    vec3 col = dayBlue;

    // --- Dusk / sunset (ported from web-minecraft sky.js) ---
    // A banded wash over the whole sky driven by the sun's elevation:
    //   red-orange horizon -> amber band -> vivid magenta -> deep violet zenith.
    // Peaks when the sun sits on the horizon, gone by ~0.3 elevation.
    float duskF = clamp(1.0 - abs(sunUp) / 0.30, 0.0, 1.0);
    float sunFacing = max(dot(viewDir, sunDir), 0.0);

    vec3 duskGlow = vec3(1.00, 0.42, 0.12);
    vec3 duskRed  = vec3(0.80, 0.14, 0.05);
    vec3 duskAmb  = vec3(1.00, 0.58, 0.10);
    vec3 duskMag  = vec3(0.80, 0.10, 0.32);
    vec3 duskZen  = vec3(0.17, 0.05, 0.24);
    vec3 sunset = mix(duskRed, duskAmb, smoothstep(0.00, 0.09, h));
    sunset = mix(sunset, duskMag, smoothstep(0.10, 0.42, h));
    sunset = mix(sunset, duskZen, smoothstep(0.42, 0.88, h));

    // The gradient fills the sky, a touch stronger toward the sun's side.
    float fill = duskF * (0.72 + 0.28 * pow(sunFacing, 2.0));
    col = mix(col, sunset, clamp(fill, 0.0, 1.0) * 0.92);
    // Warm glow hugging the horizon around the sun.
    col += duskGlow * duskF * pow(sunFacing, 3.0) * pow(max(1.0 - abs(h), 0.0), 5.0) * 0.45;

    gl_FragData[0] = vec4(col, 1.0);
}

/* DRAWBUFFERS:0 */
