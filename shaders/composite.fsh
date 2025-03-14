#version 430 compatibility

in vec3 worldDir;

uniform vec3 cameraPositionFract;
uniform sampler2D colortex0;
layout(r32ui) uniform readonly uimage3D voxelImg;

#include "/lib/raytrace.glsl"

void main() {
    vec4 col = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
    vec3 hitNormal;
    bool hitEmission;
    vec3 hitPos = voxelRT(cameraPositionFract + VOXEL_DIST, 50 * normalize(worldDir), hitNormal, hitEmission);
    col.rgb = mix(0.5 * hitNormal + 0.5, col.rgb, 0.8);
    /* RENDERTARGETS:0 */
    gl_FragData[0] = col;
}