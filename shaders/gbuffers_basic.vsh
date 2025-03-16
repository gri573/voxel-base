#version 430 compatibility

out vec4 vertexCol;
out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexCol = gl_Color;
}