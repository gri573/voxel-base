#version 430 compatibility

in vec4 vertexCol;
in vec2 texCoord;
in vec3 normal;

uniform sampler2D tex;
uniform vec4 entityColor;

void main() {
    vec4 col = texture(tex, texCoord) * vertexCol;
    col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
    /*RENDERTARGETS:0,1*/
    gl_FragData[0] = col;
    gl_FragData[1] = vec4(normal * 0.5 + 0.5, 1.0);
}