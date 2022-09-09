#version 330 compatibility

#include "/lib/common.glsl"

out vec2 texCoordV;
out vec2 lmCoordV;
out vec3 normalV;
out vec4 vertexColV;
out vec3 posV;
flat out int matV;
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;

void main() {
    vec4 pos0 = gl_ModelViewMatrix * gl_Vertex;
    posV = (shadowModelViewInverse * pos0).xyz;
    gl_Position = gl_ProjectionMatrix * pos0;
    gl_Position /= gl_Position.w;
    texCoordV = mc_midTexCoord; //(gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoordV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    normalV = mat3(shadowProjectionInverse) * (gl_NormalMatrix * gl_Normal).xyz;
    vertexColV = gl_Color;
    matV = int(mc_Entity.x + 0.5);
}
