#version 330 compatibility

flat out int mat;
out vec2 texCoord;
out vec2 lmCoord;
out vec3 worldPos;
out vec4 vertexCol;
out vec3 normal;

uniform mat4 gbufferModelViewInverse;
in vec4 mc_Entity;

void main() {
    mat = int(mc_Entity.x + 0.5);
    mat = mat / 10000 * 10000 + mat % 2000 / 4 * 4;
    vertexCol = gl_Color;
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    worldPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    normal = gl_Normal;
}