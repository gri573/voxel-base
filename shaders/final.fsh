#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex10;
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
vec2 viewSize = vec2(viewWidth, viewHeight);

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
/*    vec2 tex8size = vec2(textureSize(colortex10, 0));
    vec2 t8coord = (ivec2(texcoord * viewSize) + 0.5) / tex8size;
    vec2 shadowcoord = texcoord * viewSize / shadowMapResolution/2;
    if (shadowcoord.x < 1 && shadowcoord.y < 1) {
        ivec4 lightData = ivec4(texture2D(colortex10, t8coord) * 65535 + 0.5);
        color = vec3(lightData.y, lightData.y, lightData.z) / 65535;//vec3(lightData.x % 16, (lightData.x >> 4) % 16, (lightData.x >> 8) % 16) / 16.0;
    } else color = vec3(0);
    if (length(color - vec3(0)) < 0.001) {
        color = texture2D(colortex0, texcoord).xyz;
    }*/
    /*RENDERTARGETS: 0*/
    gl_FragData[0] = vec4(color, 1);
}