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
uniform sampler2D colortex10;
uniform sampler2D colortex15;
ivec2 atlasSize = textureSize(colortex15, 0);

vec2 tex8size = vec2(textureSize(colortex8, 0));

ivec3[7] offsets = ivec3[7](ivec3(0), ivec3(-1, 0, 0), ivec3(0, -1, 0), ivec3(0, 0, -1), ivec3(1, 0, 0), ivec3(0, 1, 0), ivec3(0, 0, 1));

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/raytrace.glsl"

void main() {
    ivec4 dataToWrite0;
    ivec4 dataToWrite1;
    ivec2 shadowCoord = ivec2(texCoord * tex8size);
    if (shadowCoord.x < shadowMapResolution && shadowCoord.y < shadowMapResolution) {
        dataToWrite0 = ivec4(texelFetch(colortex8, shadowCoord, 0) * 65535 + 0.5);
        dataToWrite1 = ivec4(texelFetch(colortex10, shadowCoord, 0) * 65535 + 0.5);
        vec3 pos0 = getVxPos(shadowCoord);
        vec3 pos = pos0;
        vec3 offset0 = floor(cameraPosition) - floor(previousCameraPosition);
        vec3 offset = offset0;
        vec3 oldPos = pos + offset;
        bool doSunLight = (int(pos.y) % SUN_CHECK_INTERVAL == frameCounter % SUN_CHECK_INTERVAL);
        ivec4 sunData0 = ivec4(texelFetch(colortex10, getVxPixelCoords(oldPos), 0) * 65535 + 0.5);
        int sunFF = sunData0.x % 4;
        int shadowFF = (sunData0.x >> 2) % 4;
        for (int i = 1; i < 7; i++) {
            if (!isInRange(oldPos + offsets[i])) continue;
            ivec4 sunData = ivec4(texelFetch(colortex10, getVxPixelCoords(oldPos + offsets[i]), 0) * 65535 + 0.5);
            sunFF = max(sunFF, sunData.x % 4 - 1);
            shadowFF = max(shadowFF, (sunData.x >> 2) % 4 - 1);
        }
        if (doSunLight && !(shadowFF == 0 ^^ sunFF == 0)) {
            vec3 pos1 = pos;
            vec4 sunOcclusion = raytrace(pos1, sunDir * sign(sunDir.y) * vxRange, colortex15);
            sunFF = sunOcclusion.a > 0.5 ? 0 : SUN_CHECK_SPREAD;
            shadowFF = sunOcclusion.a > 0.5 ? SUN_CHECK_SPREAD : 0;
        }
        int sunLightData = sunFF + (shadowFF << 2);
        int newOcclusionData = 0;
        for (int k = 0; k < 5; k++) {
            vec3 oldPos0 = pos0 + offset;
            int occlusionData = (length(offset) < 0.5) ? dataToWrite0.y : int(texelFetch(colortex8, getVxPixelCoords(oldPos0), 0).g * 65535 + 0.5);
            occlusionData = (occlusionData >> 3 * k) % 8;
            ivec4 lightData0 = ivec4(texelFetch(colortex8, getVxPixelCoords(pos), 0) * 65535 + 0.5);
            ivec4 lightData1 = ivec4(texelFetch(colortex9, getVxPixelCoords(pos), 0) * 65535 + 0.5);
            bool sunDone = (k == 0);
            if ((doSunLight || !isInRange(oldPos0)) && k > 0) {
                ivec4 sunColData = ivec4(texelFetch(colortex10, getVxPixelCoords(pos + offset), 0) * 65535 + 0.5);
                if (k == 4 || (sunColData.x % 4 > 0 && (sunColData.x >> 2) % 4 > 0) || !isInRange(oldPos0)) {
                    sunDone = true;
                    vec3 pos1 = pos;
                    vec4 sunOcclusion = raytrace(pos1, sunDir * sign(sunDir.y) * vxRange, colortex15);
                    sunLightData += (sunOcclusion.w > 0.5 ? 0 : 1) << (k + 3);
                }
            }
            if (!sunDone) {
                sunLightData += ((int(texelFetch(colortex10, getVxPixelCoords(oldPos0), 0).x * 65535 + 0.5) >> (3 + k)) % 2) << (3 + k);
            }
            int changed = isInRange(oldPos0) ? lightData0.x % 256 : 1;
            if (changed > 0) {
                occlusionData = 0;
                vec3[3] lights = vec3[3](
                    vec3(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256),
                    vec3(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256),
                    vec3(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256)
                );
                ivec3 intensities = ivec3(lightData0.w >> 8, lightData1.y >> 8, lightData1.w >> 8);
                for (int i = 0; i < 3; i++) {
                    if (intensities[i] == 0) continue;
                    vec3 lightDir = lights[i] - 127.5 - fract(pos);
                    vec3 endPos = pos;
                    vec3 goalPos = pos + lightDir;
                    raytrace(endPos, lightDir, colortex15);
                    float dist = max(max(abs(endPos.x - goalPos.x), abs(endPos.y - goalPos.y)), abs(endPos.z - goalPos.z));
                    if (dist < 0.505) {
                        occlusionData += 1 << i;
                    }
                }
            }
            newOcclusionData += occlusionData << (3 * k);
            pos *= 0.5;
            offset *= 2;
        }
        dataToWrite0.y = newOcclusionData;
        dataToWrite1.x = sunLightData;// + ((dataToWrite1.x >> 8) << 8);
    }
    /*RENDERTARGETS:8,10*/
    gl_FragData[0] = vec4(dataToWrite0) / 65535.0;
    gl_FragData[1] = vec4(dataToWrite1) / 65535.0;
}