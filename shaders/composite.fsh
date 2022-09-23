#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;

uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"

ivec3[7] offsets = ivec3[7](ivec3(0), ivec3(-1, 0, 0), ivec3(0, -1, 0), ivec3(0, 0, -1), ivec3(1, 0, 0), ivec3(0, 1, 0), ivec3(0, 0, 1));

/*
flood fill data:
 - colortex8:
    r: material hash, changed
    g: visibilities of light sources at different levels of detail
    b: position of light source 1 x, y
    a: position of light source 1 z, intensity
 - colortex9:
    r: position of light source 2 x, y
    g: position of light source 2 z, intensity
    b: position of light source 3 x, y
    a: position of light source 3 z, intensity
*/

void main() {
    vec2 debugData = vec2(0);
    vec2 tex8size = vec2(textureSize(colortex8, 0));
    vec2 shadowCoord = texCoord * tex8size / shadowMapResolution;
    ivec4 dataToWrite0;
    ivec4 dataToWrite1;
    if (max(shadowCoord.x, shadowCoord.y) < 1) {
        vec3 pos = getVxPos(shadowCoord);
        vxData blockData = readVxMap(shadowCoord);
        vec3 oldPos = pos + floor(cameraPosition) - floor(previousCameraPosition);
        ivec4[7] aroundData0;
        ivec4[7] aroundData1;
        vec2 oldCoords = getVxCoords(oldPos) * shadowMapResolution / tex8size;
        aroundData0[0] = ivec4(texture2D(colortex8, oldCoords) * 65535 + 0.5);
        aroundData1[0] = (aroundData0[0].w >> 8 > 0) ? ivec4(texture2D(colortex9, oldCoords) * 65535 + 0.5) : ivec4(0);
        int changed = isInRange(oldPos) ? 0 : 1;
        int prevchanged = aroundData0[0].x % 256;
        int newhash =  blockData.mat / 4 % 256;
        int mathash = isInRange(oldPos) ? aroundData0[0].x >> 8 : (blockData.emissive ? 0 : newhash);
        if (mathash != newhash) {
            changed = blockData.emissive ? blockData.lightlevel : aroundData0[0].w >> 8;
            mathash = newhash;
        }
        for (int k = 1; k < 7; k++) {
            vec3 aroundPos = oldPos + offsets[k];
            if (isInRange(aroundPos)) {
                vec2 aroundCoords = getVxCoords(aroundPos) * shadowMapResolution / tex8size;
                aroundData0[k] = ivec4(texture2D(colortex8, aroundCoords) * 65535 + 0.5);
                aroundData1[k] = ivec4(texture2D(colortex9, aroundCoords) * 65535 + 0.5);
                int aroundChanged = aroundData0[k].x % 256;
                if (aroundChanged > changed + 1) {
                    changed = aroundChanged - 1;
                }
            } else aroundData0[k] = ivec4(0);
        }
        dataToWrite0 = aroundData0[0];
        dataToWrite0.y = int(texture2D(colortex8, getVxCoords(pos) * shadowMapResolution / tex8size).g * 65535 + 0.5);
        dataToWrite1 = aroundData1[0];
        dataToWrite0.x = changed + 256 * mathash;
        if (changed > 0) {
            ivec4 sources[3] = ivec4[3](ivec4(0), ivec4(0), ivec4(0));
            if (blockData.emissive) {
                sources[0] = ivec4(128, 128, 128, blockData.lightlevel);
                dataToWrite0.y = 60000;
            }
            for (int k = 1; k < 7; k++) {
                ivec2[3] theselights = ivec2[3](aroundData0[k].zw, aroundData1[k].xy, aroundData1[k].zw);
                for (int i = 0; i < 3; i++) {
                    ivec4 thisLight = ivec4(theselights[i].x % 256, theselights[i].x >> 8, theselights[i].y % 256, theselights[i].y >> 8);
                    thisLight.xyz += offsets[k];
                    thisLight.w -= 1;//16 - (abs(thisLight.x) + abs(thisLight.y) + abs(thisLight.z));
                    bool newLight = true;
                    vec3 thisNormLight = normalize(thisLight.xyz - 128);
                    for (int j = 0; j < 3; j++)
                    if (length(thisLight.xyz - sources[j].xyz) < 0.2 * length(thisLight.xyz - 128)) {
                        newLight = false;
                        if (sources[j].w < thisLight.w) sources[j] = thisLight;
                    }
                    if (thisLight.w > 0 && newLight) {
                        int j = 3;
                        while (j > 0 && thisLight.w >= sources[j - 1].w) j--;
                        for (int l = 1; l >= j; l--) sources[l + 1] = sources[l];
                        if (j < 3) sources[j] = thisLight;
                    }
                }
            }
            dataToWrite0.zw = ivec2(
                sources[0].x + (sources[0].y << 8),
                sources[0].z + (sources[0].w << 8));
            dataToWrite1 = ivec4(
                sources[1].x + (sources[1].y << 8),
                sources[1].z + (sources[1].w << 8),
                sources[2].x + (sources[2].y << 8),
                sources[2].z + (sources[2].w << 8));
        }
    }
    /*RENDERTARGETS:8,9*/
    gl_FragData[0] = vec4(dataToWrite0) / 65535.0;
    gl_FragData[1] = vec4(dataToWrite1) / 65535.0;
}