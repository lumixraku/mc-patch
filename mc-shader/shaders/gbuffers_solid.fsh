#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec3 vNormal;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 upPosition;

float envLightFactor(vec2 lm) {
    float sky = clamp(lm.t, 0.0, 1.0);
    float torch = clamp(lm.s, 0.0, 1.0);
    return clamp(max(sky, torch*torch), 0.0, 1.0);
}

vec3 shade(vec3 c, vec3 n, float envL){
    vec3 N = normalize(n);
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir  = normalize(upPosition);
    float sunUp = dot(sunDir, upDir);
    float day  = clamp(sunUp, 0.0, 1.0);
    float moon = clamp(-sunUp, 0.0, 1.0);
    vec3 L = (sunUp >= 0.0) ? sunDir : -sunDir;
    float wrap = mix(0.05, 0.35, day);
    float ndl = max((dot(N,L)+wrap)/(1.0+wrap), 0.0);
    float ambient = mix(0.10, 0.55, envL);
    float lit = ambient + ndl * 0.7 * (day*1.0 + moon*0.06);
    return clamp(c * lit, 0.0, 1.0);
}

void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;
    float envL = envLightFactor(lmcoord);
    albedo.rgb = shade(albedo.rgb, vNormal, envL);
    albedo.a = 1.0; // enforce opaque for solid pass
    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
