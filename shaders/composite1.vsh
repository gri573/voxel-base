#version 330 compatibility

#include "/lib/common.glsl"

out vec2 texCoord;
out vec3 sunDir;

uniform int worldTime;

void main() {
    float dayTime = (worldTime % 24000) * 0.0002618;
    sunDir = vec3(cos(dayTime), sin(dayTime) * cos(SUN_ANGLE), sin(dayTime) * sin(SUN_ANGLE));
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    texCoord = 0.5 * gl_Position.xy + 0.5;
}