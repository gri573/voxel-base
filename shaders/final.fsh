#version 430 compatibility

uniform sampler2D colortex0;

/*
const int colortex0Format = rgba16f;
const int colortex2Format = rg32f;
*/

void main() {
    gl_FragData[0] = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
}