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
    vec3 hitNormal;
    bool hitEmission;
    vec3 hitPos = ssRT(
        cameraPositionFract + gbufferModelViewInverse[3].xyz + VOXEL_DIST + 0.5 + normalize(worldDir),
        50 * normalize(worldDir) - 3.0,
        hitNormal,
        hitEmission
    );
    if (gl_FragCoord.x > 300) {
        if (hitPos == clamp(hitPos, 0.0, 1.0)) {
            col.rgb = texture(colortex0, hitPos.xy).rgb;
        } else {
            col.rgb = mix(col.rgb, vec3(0.5), 0.5);
        }
    }
    /* RENDERTARGETS:0 */
    gl_FragData[0] = col;
}