#version 430 compatibility

out vec3 worldDir;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = ftransform();
    worldDir =
        mat3(gbufferModelViewInverse) *
        (gbufferProjectionInverse * gl_Position).xyz;
}