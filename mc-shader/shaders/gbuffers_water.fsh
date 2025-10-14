#version 120

uniform sampler2D texture;
uniform float frameTimeCounter;

varying vec2 texcoord;

// Gentle surface waves affect shading slightly
float waves(vec2 uv) {
    vec2 w1 = uv * 8.0 + vec2(frameTimeCounter * 0.10, frameTimeCounter * 0.05);
    vec2 w2 = uv * 12.0 + vec2(-frameTimeCounter * 0.08, frameTimeCounter * 0.12);
    return 0.5 + 0.5 * (sin(w1.x) * 0.5 + cos(w1.y) * 0.5 + sin(w2.x * 0.7) * 0.3);
}

void main() {
    // Base water sample (vanilla water texture)
    vec4 base = texture2D(texture, texcoord);

    // Target: soft translucent green with gentle wave modulation
    vec3 greenWater = vec3(0.2, 0.45, 0.35);
    float w = waves(texcoord);
    vec3 color = mix(greenWater * 0.9, greenWater * 1.1, w);

    // Keep some of vanilla texture detail
    color = mix(color, base.rgb, 0.15);

    // Semi-transparency. Many pipelines ignore alpha here, but when respected,
    // this gives a softer look.
    float alpha = 0.75;

    gl_FragData[0] = vec4(color, alpha);
}

