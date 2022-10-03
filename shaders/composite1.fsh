// calculate visibility of light sources

#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;
in vec3 sunDir;

uniform int frameCounter;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
#ifdef SUN_SHADOWS
uniform sampler2D colortex10;
#endif
uniform sampler2D colortex15; // texture atlas
ivec2 atlasSize = textureSize(colortex15, 0);

vec2 tex8size = vec2(textureSize(colortex8, 0));

ivec3[7] offsets = ivec3[7](ivec3(0), ivec3(-1, 0, 0), ivec3(0, -1, 0), ivec3(0, 0, -1), ivec3(1, 0, 0), ivec3(0, 1, 0), ivec3(0, 0, 1));
vec3[6] randomOffsets = vec3[6](vec3(0.64, -0.05, 0.46), vec3(0.39, -0.93, 0.92), vec3(-0.52, -0.42, -0.06), vec3(0.28, 0.11, 0.51), vec3(0.87, 0.6, 0.3), vec3(-0.15, 0.04, -0.97));

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/raytrace.glsl"

void main() {
    ivec4 dataToWrite0;
    ivec4 dataToWrite1;
    ivec2 pixelCoord = ivec2(texCoord * tex8size);
    if (max(pixelCoord.x, pixelCoord.y) < shadowMapResolution) {
        dataToWrite0 = ivec4(texelFetch(colortex8, pixelCoord, 0) * 65535 + 0.5);
        #ifdef SUN_SHADOWS
        dataToWrite1 = ivec4(texelFetch(colortex10, pixelCoord, 0) * 65535 + 0.5);
        #endif
        vec3 pos0 = getVxPos(pixelCoord);
        vec3 pos = pos0;
        vec3 offset0 = floor(cameraPosition) - floor(previousCameraPosition);
        vec3 offset = offset0;
        vec3 oldPos = pos + offset;
        // only do sunlight every SUN_CHECK_INTERVAL frames
        #ifdef SUN_SHADOWS
        bool doSunLight = (int(pos.y) % SUN_CHECK_INTERVAL == frameCounter % SUN_CHECK_INTERVAL);
        ivec4 sunData0 = ivec4(texelFetch(colortex10, getVxPixelCoords(oldPos), 0) * 65535 + 0.5);
        // nearness of voxels with sunlight / shadow
        int sunFF = sunData0.x % 4;
        int shadowFF = (sunData0.x >> 2) % 4;
        // propagate it
        for (int i = 1; i < 7; i++) {
            if (!isInRange(oldPos + offsets[i])) continue;
            ivec4 sunData = ivec4(texelFetch(colortex10, getVxPixelCoords(oldPos + offsets[i]), 0) * 65535 + 0.5);
            sunFF = max(sunFF, sunData.x % 4 - 1);
            shadowFF = max(shadowFF, (sunData.x >> 2) % 4 - 1);
        }
        // update only if there's either no sun- or shadow data available (first frame) or both (edge areas)
        if (doSunLight && !(shadowFF == 0 ^^ sunFF == 0)) {
            vec3 pos1 = pos;
            vec4 sunOcclusion = raytrace(pos1, sunDir * sign(sunDir.y) * vxRange, colortex15);
            sunFF = sunOcclusion.a > 0.5 ? 0 : SUN_CHECK_SPREAD;
            shadowFF = sunOcclusion.a > 0.5 ? SUN_CHECK_SPREAD : 0;
        }
        int sunLightData = sunFF + (shadowFF << 2); // this will be written to colortex10.x
        #endif
        int newOcclusionData = 0;
        // do occlusion checks at different zoom levels
        for (int k = 0; k < OCCLUSION_CASCADE_COUNT; k++) {
            // oldPos0 is the position this iteration had on the voxel map in the previous frame
            vec3 oldPos0 = pos0 + offset;
            int occlusionData = (length(offset) < 0.5) ? dataToWrite0.y : int(texelFetch(colortex8, getVxPixelCoords(oldPos0), 0).g * 65535 + 0.5);
            occlusionData = (occlusionData >> 3 * k) % 8;

            //sun stuff
            #ifdef SUN_SHADOWS
            bool sunDone = (k == 0);
            if (k > 0) {
                if (doSunLight || !isInRange(oldPos0)) {
                    ivec4 sunColData = ivec4(texelFetch(colortex10, getVxPixelCoords(pos + offset), 0) * 65535 + 0.5);
                    // the update condition stops working at the last iteration for whatever reason
                    if (k == OCCLUSION_CASCADE_COUNT - 1 || (sunColData.x % 4 > 0 && (sunColData.x >> 2) % 4 > 0) || !isInRange(oldPos0)) {
                        sunDone = true;
                        vec3 pos1 = pos;
                        vec4 sunOcclusion = raytrace(pos1, sunDir * sign(sunDir.y) * vxRange + 0.01 * randomOffsets[frameCounter % 6], colortex15);
                        sunLightData += (sunOcclusion.w > 0.5 ? 0 : 1) << (k + 3);
                    }
                }/* else if (!isInRange(oldPos0)) {
                    int sunOcclusion = int(texelFetch(colortex10, getVxPixelCoords(oldPos0 * 0.5), 0).x * 65535 + 0.5);
                    sunOcclusion = (sunOcclusion >> (k + 2)) % 2;
                    sunLightData += sunOcclusion << (k + 3);
                }*/
            }
            if (!sunDone) {
                sunLightData += ((int(texelFetch(colortex10, getVxPixelCoords(oldPos0), 0).x * 65535 + 0.5) >> (3 + k)) % 2) << (3 + k);
            }
            #endif

            bool doBlockLight = (int(pos.y) % BLOCKLIGHT_CHECK_INTERVAL == frameCounter % BLOCKLIGHT_CHECK_INTERVAL);
            if (doBlockLight) {
                ivec4 lightData0 = ivec4(texelFetch(colortex8, getVxPixelCoords(pos), 0) * 65535 + 0.5);
                ivec4 lightData1 = ivec4(texelFetch(colortex9, getVxPixelCoords(pos), 0) * 65535 + 0.5);
                int changed = isInRange(oldPos0) ? lightData0.x % 256 : 1;
                if (changed > 0) {
                    occlusionData = 0;
                    vec3[3] lights = vec3[3](
                        vec3(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256),
                        vec3(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256),
                        vec3(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256)
                    );
                    ivec3 intensities = ivec3(lightData0.w >> 8, lightData1.y >> 8, lightData1.w >> 8);
                    // check for each light source if it is occluded
                    for (int i = 0; i < 3; i++) {
                        if (intensities[i] == 0) continue;
                        vec3 lightDir = lights[i] - 127.5 - fract(pos);
                        vec3 endPos = pos;
                        vec3 goalPos = pos + lightDir;
                        float rayAlpha = raytrace(endPos, lightDir + 0.01 * randomOffsets[frameCounter % 6], colortex15, true).w;
                        float dist = max(max(abs(endPos.x - goalPos.x), abs(endPos.y - goalPos.y)), abs(endPos.z - goalPos.z));
                        if (dist < 0.505 && rayAlpha < 0.5) {
                            occlusionData += 1 << i;
                        }
                    }
                    if (k == 0 && changed == 1) {
                        dataToWrite0.x = (dataToWrite0.x >> 8) << 8;
                    }
                }
            } else if (!isInRange(oldPos0)) {
                occlusionData = int(texelFetch(colortex8, getVxPixelCoords(oldPos0 * 0.5), 0).g * 65535 + 0.5);
                occlusionData = (occlusionData >> 3 * (k-1)) % 8;
            }
            newOcclusionData += occlusionData << (3 * k);
            // zoom in
            pos *= 0.5;
            offset *= 2;
        }
        //write data
        dataToWrite0.y = newOcclusionData;
        #ifdef SUN_SHADOWS
        dataToWrite1.x = sunLightData + ((dataToWrite1.x >> 8) << 8);
        #endif
    }
    /*RENDERTARGETS:8*/
    gl_FragData[0] = vec4(dataToWrite0) / 65535.0;
    #ifdef SUN_SHADOWS
    /*RENDERTARGETS:8,10*/
    gl_FragData[1] = vec4(dataToWrite1) / 65535.0;
    #endif
}