#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D colortex15;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
vec2 atlasSize = vec2(textureSize(colortex15, 0));
#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/raytrace.glsl"

void main() {
    vec3 pos = (gbufferModelViewInverse * (gbufferProjectionInverse * vec4(2 * texCoord - 1, 0.25, 1))).xyz;
    vec4 raycolor = raytrace(getVxPos(vec3(0)), pos * 20, colortex15);
    vec3 color = mix(vec3(0.5, 0.7, 1.0), raycolor.xyz, raycolor.a);
    gl_FragData[0] = vec4(color, 1);
}