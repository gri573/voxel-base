#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;
flat in int spriteSize;
in vec2 lmCoord;
in vec3 normal;
in vec4 vertexCol;
in vec3 pos;
flat in int mat;

uniform sampler2D tex;
uniform sampler2D shadowcolor1;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

vec2[8] offsets = vec2[8](
    vec2(3, -3), vec2(3, 0), vec2(3, 3), vec2(0, 3), vec2(-3, 3), vec2(-3, 0), vec2(-3, -3), vec2(0, -3)
);

#include "/lib/vx/voxelMapping.glsl"

void main() {
    bool emissive, alphatest, crossmodel, cuboid, full, entity;
    vec3 lightcol = vec3(0);
    ivec3[2] bounds = ivec3[2](ivec3(0), ivec3(16));
    #include "/lib/materials/shadowchecks.glsl"
    if (emissive && length(lightcol) < 0.001) {
        vec4 lightcol0 = texture2D(tex, texCoord);
        for (int i = 0; i < 8 && lightcol0.a < 0.1; i++) {
            lightcol0 = texture2D(tex, texCoord + offsets[i] / atlasSize);
        }
        lightcol = lightcol0.rgb;
    }
    if (!emissive) lightcol = vertexCol.rgb;
    ivec4 packedData0 = ivec4(
        int(lightcol.r * 255) + int(lightcol.g * 255) * 256,
        int(lightcol.b * 255) + (int(texCoord.x * 4095) / 16) * 256,
        int(texCoord.x * 4095) % 16 + int(texCoord.y * 4095) * 16,
        mat);
    
    bounds[1] -= 1;
    int blocktype = (alphatest ? 1 : 0) + (crossmodel ? 2 : 0) + (full ? 4 : 0) + (emissive ? 8 : 0) + (cuboid ? 16 : 0) + (entity ? 32 : 0);
    int spritelog = 0;
    while (spriteSize >> spritelog + 1 != 0 && spritelog < 15) spritelog++;

    ivec4 packedData1 = ivec4(
        bounds[0].x + 16 * bounds[0].y + 256 * bounds[0].z + 4096 * bounds[1].x,
        bounds[1].y + 16 * bounds[1].z + 256 * blocktype,
        spritelog,
        0
    );
    
    /*RENDERTARGETS:0,1*/
    gl_FragData[0] = vec4(packedData0) / 65535;
    gl_FragData[1] = vec4(packedData1) / 65535;
}