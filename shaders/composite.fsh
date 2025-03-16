#version 430 compatibility

in vec3 worldDir;

uniform float near, far;
uniform float viewWidth, viewHeight;
uniform vec3 cameraPositionFract;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D colortex0;
uniform sampler2D depthtex1;
layout(r32ui) uniform readonly uimage3D voxelImg;

#include "/lib/raytrace.glsl"

/*
const int colortex0Format = rgba16f;
*/

void main() {
    vec4 col = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
    vec3 normal;
    bool emissive = true;
    //vec3 hitPos = voxelRT(cameraPositionFract + VOXEL_DIST, 50 * normalize(worldDir), normal, emissive);
    //if (emissive) col.rgb = vec3(1, 0, 1);
    /* RENDERTARGETS:0 */
    gl_FragData[0] = col;
}