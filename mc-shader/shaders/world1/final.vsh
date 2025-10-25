#version 150
// Chocapic-style fullscreen triangle using gl_VertexID
void main() {
    int id = gl_VertexID % 3;
    vec2 pos = id == 0 ? vec2(-1.0, -1.0)
             : id == 1 ? vec2( 3.0, -1.0)
                        : vec2(-1.0,  3.0);
    gl_Position = vec4(pos, 0.0, 1.0);
}
