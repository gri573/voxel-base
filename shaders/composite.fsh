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

void main() {
    vec4 col = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
    vec4 hitPos = gbufferProjection * gbufferModelView * vec4(hybridRT(
        cameraPositionFract + gbufferModelViewInverse[3].xyz + 1.0 + VOXEL_DIST + normalize(worldDir),
        50 * normalize(worldDir)
    ) - cameraPositionFract - VOXEL_DIST, 1.0);
    hitPos /= hitPos.w;
    hitPos.xyz = 0.5 * hitPos.xyz + 0.5;
    if (gl_FragCoord.x > 300) {
        if (
            hitPos.xyz == clamp(hitPos.xyz, 0.0, 1.0) &&
            hitPos.z < 0.999 &&
            abs(hitPos.z - textureLod(depthtex1, hitPos.xy, 0).r) < 0.001) {
            col.rgb = texture(colortex0, hitPos.xy).rgb;
        } else {
            col.rgb = hitPos.xyz * (hitPos.z < 0.999 ? 1.0 : 0.3);
        }
    }
    /* RENDERTARGETS:0 */
    gl_FragData[0] = col;
}