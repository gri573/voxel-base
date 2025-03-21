#version 430 compatibility

uniform sampler2D colortex4;

/*
const int colortex0Format = rgba16f;
const int colortex2Format = rg16;
const int colortex3Format = r32ui;
const int colortex4Format = rgba16f;
*/

const bool colortex3Clear = false;

void main() {
    gl_FragData[0] = texelFetch(colortex4, ivec2(gl_FragCoord.xy), 0);
}