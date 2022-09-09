#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D shadowcolor0;
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
vec2 viewSize = vec2(viewWidth, viewHeight);

void main() {
    vec3 color;
    vec2 shadowcoord = (vec2(0.5) + ivec2(texcoord * viewSize) / 5) / shadowMapResolution;
    if (max(shadowcoord.x, shadowcoord.y) < 1) {
        color = texture2D(shadowcolor0, shadowcoord).xyz;
    } else color = vec3(1);
    if (length(color - vec3(1)) < 0.01) {
        color = texture2D(colortex0, texcoord).xyz;
    }
    /*RENDERTARGETS: 0*/
    gl_FragData[0] = vec4(color, 1);
}