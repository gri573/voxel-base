#version 330 compatibility

#include "/lib/common.glsl"

out vec2 texCoord;
out vec3 sunDir;

uniform int worldTime;
uniform sampler2D colortex8;

void main() {
    const vec2 sunRotationData = vec2(cos(SUN_ANGLE), sin(SUN_ANGLE));
    float ang = worldTime % 24000 * 0.0002617993877991494;
    sunDir = vec3(cos(ang), sin(ang) * sunRotationData);;
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    gl_Position.xy = (0.5 * gl_Position.xy + 0.5) * shadowMapResolution / vec2(textureSize(colortex8, 0)) * 2.0 - 1.0;
    texCoord = 0.5 * gl_Position.xy + 0.5;
}