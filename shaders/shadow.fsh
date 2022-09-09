#version 330 compatibility
in vec2 texCoord;
in vec2 lmCoord;
in vec3 normal;
in vec4 vertexCol;
in vec3 pos;
flat in int mat;

uniform sampler2D tex;

void main() {
    bool emissive, alphatest, crossmodel, cuboid, full;
    vec3[2] bounds;
    #include "/lib/materials/matchecks.glsl"
    vec4 color = texture2D(tex, texCoord) * vertexCol;
    /*RENDERTARGETS:0*/
    gl_FragData[0] = color;//vec4(fract(pos), 1.0);
}