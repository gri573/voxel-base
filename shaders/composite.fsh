// propagate blocklight data

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
    ivec2 pixelCoord = ivec2(texCoord * tex8size);
    ivec4 dataToWrite0;
    ivec4 dataToWrite1;
    if (max(pixelCoord.x, pixelCoord.y) < shadowMapResolution) {
        vxData blockData = readVxMap(pixelCoord);
        vec3 pos = getVxPos(pixelCoord);
        vec3 oldPos = pos + floor(cameraPosition) - floor(previousCameraPosition);
        bool previouslyInRange = isInRange(oldPos, 1);
        ivec4[7] aroundData0;
        ivec4[7] aroundData1;
        int changed;
        if (previouslyInRange) {
            ivec2 oldCoords = getVxPixelCoords(oldPos);
            aroundData0[0] = ivec4(texelFetch(colortex8, oldCoords, 0) * 65535 + 0.5);
            aroundData1[0] = ivec4(texelFetch(colortex9, oldCoords, 0) * 65535 + 0.5);
            int prevchanged = aroundData0[0].x % 256;
            changed = (prevchanged == 0) ? 0 : max(prevchanged - 1, 1); // need to update if voxel is new
        } else changed = 1;
        // newhash and mathash are hashes of the material ID, which change if the block at the given location changes, so it can be detected
        int newhash =  blockData.mat > 0 ? blockData.mat / 4 % 255 + 1 : 0;
        int mathash = previouslyInRange ? aroundData0[0].x >> 8 : 0;
        // if the material changed, then propagate that
        if (mathash != newhash) {
            // the change will not have any effects if it occurs further away than the light level at its location, because any light that passes through that location has faded out by then
            changed = blockData.emissive ? blockData.lightlevel : aroundData0[0].w >> 8;
            mathash = newhash;
        }
        //check for changes in surrounding voxels and propagate them
        for (int k = 1; k < 7; k++) {
            vec3 aroundPos = oldPos + offsets[k];
            if (isInRange(aroundPos)) {
                ivec2 aroundCoords = getVxPixelCoords(aroundPos);
                aroundData0[k] = ivec4(texelFetch(colortex8, aroundCoords, 0) * 65535 + 0.5);
                aroundData1[k] = ivec4(texelFetch(colortex9, aroundCoords, 0) * 65535 + 0.5);
                int aroundChanged = aroundData0[k].x % 256;
                changed = max(aroundChanged - 1, changed);
            } else aroundData0[k] = ivec4(0);
        }
        // copy data so it is written back to the buffer if unchanged
        dataToWrite0.xzw = aroundData0[0].xzw;
        dataToWrite0.y = int(texelFetch(colortex8, getVxPixelCoords(pos), 0).y * 65535 + 0.5);
        dataToWrite1 = aroundData1[0];
        dataToWrite0.x = changed + 256 * mathash;
        if (changed > 0) {
            // sources will contain nearby light sources, sorted by intensity
            ivec4 sources[3] = ivec4[3](ivec4(0), ivec4(0), ivec4(0));
            if (blockData.emissive) {
                sources[0] = ivec4(128, 128, 128, blockData.lightlevel);
                dataToWrite0.y = 60000;
            }
            for (int k = 1; k < 7; k++) {
                // current surrounding (sorted but still compressed) light data
                ivec2[3] theselights = ivec2[3](aroundData0[k].zw, aroundData1[k].xy, aroundData1[k].zw);
                for (int i = 0; i < 3; i++) {
                    //unpack and adjust light data
                    ivec4 thisLight = ivec4(theselights[i].x % 256, theselights[i].x >> 8, theselights[i].y % 256, theselights[i].y >> 8);
                    thisLight.xyz += offsets[k];
                    thisLight.w -= 1;
                    if (thisLight.w <= 0) continue; // ignore light sources with zero intensity
                    bool newLight = true;
                    for (int j = 0; j < 3; j++) {
                    // if there is a nearby light already registered, assume they are the same (nearness suffices in order to retain more diverse information)
                        if (length(vec3(thisLight.xyz - sources[j].xyz)) < 0.2 * length(vec3(thisLight.xyz - 128)) + 0.01) {
                            newLight = false;
                            if (j > 0 && sources[j-1].w < thisLight.w) {
                                sources[j] = sources[j-1];
                                sources[j-1] = thisLight;
                            }
                            else if (sources[j].w < thisLight.w) sources[j] = thisLight;
                            break;
                        }
                    }
                    if (newLight) {
                        // sort by intensity, to keep the brightest light sources
                        int j = 3;
                        while (j > 0 && thisLight.w >= sources[j - 1].w) j--;
                        for (int l = 1; l >= j; l--) sources[l + 1] = sources[l];
                        if (j < 3) sources[j] = thisLight;
                    }
                }
            }
            // write new light data
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