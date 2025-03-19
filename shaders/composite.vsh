#version 430 compatibility
#include "/lib/voxel_settings.glsl"

void main() {
    #ifdef FINE_SSRT
    gl_Position = ftransform();
    #else
    gl_Position = vec4(-1);
    #endif
}