#version 330 compatibility

#include "/lib/common.glsl"

uniform sampler2D colortex8;
out vec2 texCoord;

void main() {
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    gl_Position.xy = (0.5 * gl_Position.xy + 0.5) * shadowMapResolution / vec2(textureSize(colortex8, 0)) * 2.0 - 1.0;
    texCoord = 0.5 * gl_Position.xy + 0.5;
}