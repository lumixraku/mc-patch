#version 120

/* Simple brighter sky.
   By request: force a fixed azure sky color between time=3000..8000.
   Outside that window, use vanilla sky color scaled by day factor. */

varying vec4 vColor;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;

void main() {
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir  = normalize(upPosition);
    float sunUp = dot(sunDir, upDir);    // >0 day, <0 night
    float day = clamp(sunUp, 0.0, 1.0);

    // Requested azure sky for daytime window
    const vec3 SKY_BLUE = vec3(0.40, 0.70, 1.00); // photo-like blue
    float t = float(worldTime);
    bool forceAzure = (t >= 3000.0 && t <= 8000.0);

    vec3 base = vColor.rgb;
    if (forceAzure) {
        base = SKY_BLUE;
    } else {
        // Otherwise keep vanilla color but brighten with day amount
        float boost = mix(1.0, 1.35, day);
        base = clamp(base * boost, 0.0, 1.0);
    }

    vec3 rgb = base;
    gl_FragData[0] = vec4(rgb, 1.0);
}

/* DRAWBUFFERS:0 */
