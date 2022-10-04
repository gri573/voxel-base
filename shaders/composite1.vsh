#version 330 compatibility

#include "/lib/common.glsl"

out vec2 texCoord;
out vec3 sunDir;

uniform int worldTime;
uniform sampler2D colortex8;

void main() {
    float dayTime = (worldTime % 24000) * 0.0002618;
    sunDir = vec3(cos(dayTime), sin(dayTime) * cos(SUN_ANGLE), sin(dayTime) * sin(SUN_ANGLE));
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    gl_Position.xy = (0.5 * gl_Position.xy + 0.5) * shadowMapResolution / vec2(textureSize(colortex8, 0)) * 2.0 - 1.0;
    texCoord = 0.5 * gl_Position.xy + 0.5;
}