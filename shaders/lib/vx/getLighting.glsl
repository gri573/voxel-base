#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/raytrace.glsl"
#ifndef LIGHTING
#define LIGHTING
vec2 tex8size0 = vec2(textureSize(colortex8, 0));

vec3 getOcclusion(vec3 vxPos) {
    int k = 0;
    // zoom in to the highest-resolution available sub map
    for (; isInRange(2 * vxPos, 1) && k < OCCLUSION_CASCADE_COUNT - 1; k++) {
        vxPos *= 2;
    }
    vec3 occlusion = vec3(0);
    vxPos -= 0.5;
    vec3 floorPos = floor(vxPos);
    float totalInt = 1; // total intensity (calculating weighted average of surrounding occlusion data)
    for (int j = 0; j < 8; j++) {
        vec3 offset = vec3(j%2, (j>>1)%2, (j>>2)%2);
        vec3 cornerPos = floorPos + offset;
        // intensity multiplier for linear interpolation
        float intMult = (1 - abs(vxPos.x - cornerPos.x)) * (1 - abs(vxPos.y - cornerPos.y)) * (1 - abs(vxPos.z - cornerPos.z));
        // skip this corner if it is across a block boundary, to disregard dark spots on the insides of surfaces
        if (length(floor(cornerPos / (1 << k)) - floor((vxPos + 0.5) / (1 << k))) > 0.5) {
            totalInt -= intMult;
            continue;
        }
        ivec4 lightData = ivec4(texelFetch(colortex8, getVxPixelCoords(cornerPos + 0.5), 0) * 65535 + 0.5);
        for (int i = 0; i < 3; i++) occlusion[i] += ((lightData.y >> 3 * k + i) % 2) * intMult;
    }
    occlusion /= totalInt;
    return occlusion;
}
// get the blocklight value at a given position. optionally supply a normal vector to account for dot product shading
vec3 getBlockLight(vec3 vxPos, vec3 normal) {
    vec3 vxPosOld = vxPos + floor(cameraPosition) - floor(previousCameraPosition);
    if (isInRange(vxPosOld) && isInRange(vxPos)) {
        vec3 lightCol = vec3(0);
        ivec2 vxCoordsFF = getVxPixelCoords(vxPosOld);
        ivec4 lightData0 = ivec4(texelFetch(colortex8, vxCoordsFF, 0) * 65535 + 0.5);
        if (lightData0.w >> 8 == 0) return vec3(0);
        ivec4 lightData1 = (lightData0.w >> 8 > 0) ? ivec4(texelFetch(colortex9, vxCoordsFF, 0) * 65535 + 0.5) : ivec4(0);
        vec4[3] lights = vec4[3](
            vec4(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256, (lightData0.w >> 8)) - vec4(128, 128, 128, 0),
            vec4(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256, (lightData1.y >> 8)) - vec4(128, 128, 128, 0),
            vec4(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256, (lightData1.w >> 8)) - vec4(128, 128, 128, 0)
        );
        float intMult0 = (1 - abs(fract(vxPos.x) - 0.5)) * (1 - abs(fract(vxPos.y) - 0.5)) * (1 - abs(fract(vxPos.z) - 0.5));
        vec3 ndotls;
        bvec3 isHere;
        bool calcNdotLs = (normal == vec3(0));
        for (int k = 0; k < 3; k++) {
            vec3 lightDir = lights[k].xyz + 0.5 - fract(vxPos);
            isHere[k] = (max(max(abs(lightDir.x), abs(lightDir.y)), abs(lightDir.z)) < 0.511);
            if (isHere[k]) lights[k].w -= 1;
            lights[k].w *= isHere[k] ? 1 : intMult0;
            ndotls[k] = (isHere[k] || calcNdotLs) ? 1 : max(0, dot(normalize(lightDir), normal));
        }

        ndotls = min(ndotls * 2, 1);
        vec3[3] lightCols;
        ivec3 lightMats;
        for (int k = 0; k < 3; k++) {
            vxData lightSourceData = readVxMap(getVxPixelCoords(vxPos + lights[k].xyz));
            lightCols[k] = lightSourceData.lightcol;
            lightMats[k] = lightSourceData.mat;
        }
        vec3 offsetDir = sign(fract(vxPos) - 0.5);
        vec3 floorPos = floor(vxPosOld);
        for (int k = 1; k < 8; k++) {
            vec3 offset = vec3(k%2, (k>>1)%2, (k>>2)%2);
            vec3 cornerPos = floorPos + offset * offsetDir + 0.5;
            if (!isInRange(cornerPos)) continue;
            float intMult = (1 - abs(cornerPos.x - vxPosOld.x)) * (1 - abs(cornerPos.y - vxPosOld.y)) * (1 - abs(cornerPos.z - vxPosOld.z));
            ivec2 cornerVxCoordsFF = getVxPixelCoords(cornerPos);
            ivec4 cornerLightData0 = ivec4(texelFetch(colortex8, cornerVxCoordsFF, 0) * 65535 + 0.5);
            ivec4 cornerLightData1 = (cornerLightData0.w >> 8 > 0) ? ivec4(texelFetch(colortex9, cornerVxCoordsFF, 0) * 65535 + 0.5) : ivec4(0);
            vec4[3] cornerLights = vec4[3](
                vec4(cornerLightData0.z % 256, cornerLightData0.z >> 8, cornerLightData0.w % 256, (cornerLightData0.w >> 8)) - vec4(128, 128, 128, 0),
                vec4(cornerLightData1.x % 256, cornerLightData1.x >> 8, cornerLightData1.y % 256, (cornerLightData1.y >> 8)) - vec4(128, 128, 128, 0),
                vec4(cornerLightData1.z % 256, cornerLightData1.z >> 8, cornerLightData1.w % 256, (cornerLightData1.w >> 8)) - vec4(128, 128, 128, 0)
            );
            for (int j = 0; j < 3 && cornerLights[j].w > 0; j++) {
                int cornerLightMat = readVxMap(getVxPixelCoords(cornerLights[j].xyz + vxPos)).mat;
                for (int i = 0; i < 3; i++) {
                    int i0 = (i + j) % 3;
                    if (length(lights[i0].xyz - cornerLights[j].xyz - offset * offsetDir) < (cornerLightMat == lightMats[i0] ? 1.5 : 0.5)) {
                        lights[i0].w += cornerLights[j].w * intMult * (isHere[i0] ? 0 : 1);
                        break;
                    }
                }
            }
        }
        vec3 occlusionData = getOcclusion(vxPosOld);
        for (int k = 0; k < 3; k++) lightCol += lightCols[k] * occlusionData[k] * pow(lights[k].w * BLOCKLIGHT_STRENGTH / 20.0, BLOCKLIGHT_STEEPNESS) * ndotls[k];
        return lightCol;
    } else return vec3(lmCoord.x);
}

vec3 getBlockLight(vec3 vxPos) {
    return getBlockLight(vxPos, vec3(0));
}

float getSunOcclusion(vec3 vxPos) {
    int k = 0;
    // zoom in appropriately
    for (; isInRange(2 * vxPos, 1) && k < OCCLUSION_CASCADE_COUNT - 1; k++) {
        vxPos *= 2;
    }
    float occlusion = 0;
    vxPos -= 0.5;
    vec3 floorPos = floor(vxPos);
    float totalInt = 1; // track total intensity
    for (int j = 0; j < 8; j++) {
        vec3 offset = vec3(j%2, (j>>1)%2, (j>>2)%2);
        vec3 cornerPos = floorPos + offset;
        // this corner's intensity multiplier
        float intMult = (1 - abs(vxPos.x - cornerPos.x)) * (1 - abs(vxPos.y - cornerPos.y)) * (1 - abs(vxPos.z - cornerPos.z));
        // skip this corner if it is across a block boundary, to disregard dark spots on the insides of surfaces
        if (length(floor(cornerPos / (1 << k)) - floor((vxPos + 0.5) / (1 << k))) > 0.5) {
            totalInt -= intMult;
            continue;
        }
        ivec4 sunData = ivec4(texelFetch(colortex10, getVxPixelCoords(cornerPos + 0.5), 0) * 65535 + 0.5);
        occlusion += ((k == 0) ? (sunData.x % 4 == SUN_CHECK_SPREAD ? 1 : 0) : ((sunData.x >> k + 3) % 2)) * intMult;
    }
    occlusion /= totalInt;
    return occlusion;
}
vec3 getSunLight(vec3 vxPos, vec3 normal) {
    float dayTime = (worldTime % 24000) * 0.0002618;
    vec3 sunDir = vec3(cos(dayTime), sin(dayTime) * cos(SUN_ANGLE), sin(dayTime) * sin(SUN_ANGLE));
    sunDir *= sign(sunDir.y);
    float ndotl = dot(normal, sunDir); // angle based sun intensity multiplier
    if (ndotl <= 0) return vec3(0);
    float occlusion;
    if (!isInRange(vxPos)) occlusion = clamp(lmCoord.y * lmCoord.y * 4 - 2.5, 0, 1) * ndotl;
    else occlusion = getSunOcclusion(vxPos);
    return occlusion * vec3(1.0, 0.8, 0.7) * ndotl;
}
#endif