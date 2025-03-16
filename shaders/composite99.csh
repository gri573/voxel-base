#version 430

#define WRITE_LIGHTS
#include "/lib/ssbo.glsl"

const ivec3 workGroups = ivec3(1000, 1, 1);

layout(local_size_x = 1024) in;

void main() {
    lightArray[gl_GlobalInvocationID.x] = uvec4(0);
}