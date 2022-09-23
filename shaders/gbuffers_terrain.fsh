#version 330 compatibility

#include "/lib/common.glsl"

in vec2 lmCoord;
in vec2 texCoord;
in vec3 worldPos;
in vec4 vertexCol;
in vec3 normal;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D tex;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
#define TEX89
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform ivec2 atlasSize;

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/raytrace.glsl"

void main() {
    vec2 tex8size = vec2(textureSize(colortex8, 0));
    vec4 color = texture2D(tex, texCoord) * vertexCol;
    //vec3 vxPosOld = getPreviousVxPos(worldPos + 0.1 * normal);
    vec3 vxPos = getVxPos(worldPos + 0.01 * normal);
    /*if (isInRange(vxPosOld) && isInRange(vxPos)) {
        vec2 vxCoordsFF = getVxCoords(vxPosOld) * shadowMapResolution / tex8size;
        ivec4 lightData = ivec4(texture2D(colortex8, vxCoordsFF) * 65535 + 0.5);
        vec3 lightPos = vec3(lightData.z % 256, lightData.z >> 8, lightData.w % 256) - 128;
        if (lightData.w >> 8 != 0) {
            int visible = getOcclusion(vxPosOld).x;
            vec2 lightCoords = getVxCoords(vxPos + lightPos);
            vxData lightBlockData = readVxMap(lightCoords);
            color.rgb *= lightBlockData.lightcol * ((lightData.w >> 8) / 16.0 + 0.1) * vec3(visible, 1, 1);//lightPos * 0.1 + 0.5;
        }
    }*/
    vec3 lightCol = getBlockLight(vxPos, normal) + lmCoord.y * vec3(0.7, 0.8, 1.0);
    color.rgb *= lightCol;
    /*RENDERTARGETS:0*/
    gl_FragData[0] = color;
}