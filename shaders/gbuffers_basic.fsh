#version 430 compatibility

in vec4 vertexCol;
in vec2 texCoord;

uniform sampler2D tex;
uniform vec4 entityColor;

void main() {
    vec4 col = texture(tex, texCoord) * vertexCol;
    col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
    /*RENDERTARGETS:0*/
    gl_FragData[0] = col;
}