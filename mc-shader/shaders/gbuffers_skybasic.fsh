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
    const vec3 SUNSET_ORANGE = vec3(1.00, 0.55, 0.08);
    float t = float(worldTime);
    float timeIn = smoothstep(2800.0, 3000.0, t);
    float timeOut = 1.0 - smoothstep(8000.0, 8200.0, t);
    float azureWeight = clamp(timeIn * timeOut, 0.0, 1.0); // 0..1

    // View direction and altitude
    vec4 clip = vec4(gl_FragCoord.xy/vec2(viewWidth, viewHeight), 1.0, 1.0) * 2.0 - 1.0;
    vec4 vpos = gbufferProjectionInverse * clip;
    vec3 viewDir = normalize(vpos.xyz);
    float alt = clamp(dot(viewDir, upDir), 0.0, 1.0); // 0=horizon,1=zenith

    // How close are we to sunrise/sunset (sun near horizon)?
    float twilight = 1.0 - abs(sunUp);                 // 0 midday/midnight, 1 at horizon
    twilight = smoothstep(0.05, 0.22, twilight);       // wide and gentle

    // Day blue base
    vec3 vanillaBright = clamp(vColor.rgb * mix(1.0, 1.20, day), 0.0, 1.0);
    vec3 dayBlue = mix(vanillaBright, SKY_BLUE, azureWeight);

    // Twilight gradient: horizon orange -> blue with very wide vertical fade
    float vertical = smoothstep(0.0, 0.85, alt);        // 0 at horizon → 1 zenith
    vec3 twilightSky = mix(SUNSET_ORANGE, dayBlue, vertical);

    // Sun-facing bias (soft) so near-sun area warmer, but no hard edge
    float sunFacing = max(dot(viewDir, sunDir), 0.0);
    float facingBoost = mix(0.9, 1.4, pow(sunFacing, 3.5));
    twilightSky = mix(dayBlue, twilightSky, clamp(facingBoost * twilight, 0.0, 1.0));

    // Final blend: twilight amount selects between pure day blue and the gradient
    vec3 rgb = mix(dayBlue, twilightSky, twilight);
    gl_FragData[0] = vec4(rgb, 1.0);
}

/* DRAWBUFFERS:0 */
