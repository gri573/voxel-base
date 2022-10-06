#version 330 compatibility

out vec2 texCoord;
out vec4 vertexCol;

void main() {
    vertexCol = gl_Color;
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}