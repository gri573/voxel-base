#version 330 compatibility
out vec2 texcoord;

void main() {
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    texcoord = gl_Position.xy * 0.5 + 0.5;
}