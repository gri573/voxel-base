#version 330 compatibility

out vec2 texCoord;

void main() {
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    texCoord = 0.5 * gl_Position.xy + 0.5;
}