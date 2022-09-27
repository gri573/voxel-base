#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex8;
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
vec2 viewSize = vec2(viewWidth, viewHeight);

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
/*    vec2 tex8size = vec2(textureSize(colortex8, 0));
    vec2 t8coord = (ivec2(texcoord * viewSize) + 0.5) / tex8size;
    vec2 shadowcoord = texcoord * viewSize / shadowMapResolution/2;
    if (shadowcoord.x < 1 && shadowcoord.y < 1) {
        ivec4 lightData = ivec4(texture2D(colortex8, t8coord) * 65535 + 0.5);
        color = vec3(lightData.y % 2, (lightData.y >> 6) % 2, (lightData.y >> 12) % 2);
    } else color = vec3(0);
    if (length(color - vec3(0)) < 0.001) {
        color = texture2D(colortex0, texcoord).xyz;
    }*/
    /*RENDERTARGETS: 0*/
    gl_FragData[0] = vec4(color, 1);
}