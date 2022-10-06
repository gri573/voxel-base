#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;
in vec4 vertexCol;

uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, texCoord) * vertexCol;
    /*RENDERTARGETS:0*/
    gl_FragData[0] = color;
}