#version 150

in vec2 texcoord;
in vec4 color;
out vec4 fragColor;

// Base albedo/texture from the game
uniform sampler2D texture;

void main() {
    // Toggle test color (commented by default)
    // fragColor = vec4(1.0, 0.0, 0.0, 1.0);

    // Use the original material color (albedo), with vertex tint
    fragColor = texture(texture, texcoord) * color;
}
