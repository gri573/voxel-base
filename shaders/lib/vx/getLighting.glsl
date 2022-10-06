#ifndef LIGHTING
#define LIGHTING
#ifndef VOXEL_TEXTURES
#define VOXEL_TEXTURES
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
#ifdef SUN_SHADOWS
uniform sampler2D colortex10;
#endif
#endif
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/raytrace.glsl"
vec2 tex8size0 = vec2(textureSize(colortex8, 0));

vec3 getOcclusion(vec3 vxPos, vec3 normal) {
    int k = 0;
    normal *= 2.0 * max(max(abs(vxPos.x) / vxRange, abs(vxPos.y) / (VXHEIGHT * VXHEIGHT)), abs(vxPos.z) / vxRange);
    // zoom in to the highest-resolution available sub map
    for (; isInRange(2 * vxPos, 1) && k < OCCLUSION_CASCADE_COUNT - 1; k++) {
        vxPos *= 2;
    }
    vec3 occlusion = vec3(0);
    #if OCCLUSION_FILTER > 0
    vxPos += normal - 0.5;
    vec3 floorPos = floor(vxPos);
    float totalInt = 1; // total intensity (calculating weighted average of surrounding occlusion data)
    for (int j = 0; j < 8; j++) {
        vec3 offset = vec3(j%2, (j>>1)%2, (j>>2)%2);
        vec3 cornerPos = floorPos + offset;
        // intensity multiplier for linear interpolation
        float intMult = (1 - abs(vxPos.x - cornerPos.x)) * (1 - abs(vxPos.y - cornerPos.y)) * (1 - abs(vxPos.z - cornerPos.z));
        // skip this corner if it is across a block boundary, to disregard dark spots on the insides of surfaces
        if (length(floor(cornerPos / float(1 << k)) - floor((vxPos + 0.5) / float(1 << k))) > 0.5) {
            totalInt -= intMult;
            continue;
        }
        #else
        vec3 cornerPos = vxPos;
        float intMult = 1.0;
        #endif
        ivec4 lightData = ivec4(texelFetch(colortex8, getVxPixelCoords(cornerPos + 0.5), 0) * 65535 + 0.5);
        for (int i = 0; i < 3; i++) occlusion[i] += ((lightData.y >> 3 * k + i) % 2) * intMult;
    #if OCCLUSION_FILTER > 0
    }
    occlusion /= totalInt;
    #endif
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
        #if SMOOTH_LIGHTING == 2
        float intMult0 = (1 - abs(fract(vxPos.x) - 0.5)) * (1 - abs(fract(vxPos.y) - 0.5)) * (1 - abs(fract(vxPos.z) - 0.5));
        #endif
        vec3 ndotls;
        bvec3 isHere;
        bool calcNdotLs = (normal == vec3(0));
        for (int k = 0; k < 3; k++) {
            vec3 lightDir = lights[k].xyz + 0.5 - fract(vxPos);
            isHere[k] = (max(max(abs(lightDir.x), abs(lightDir.y)), abs(lightDir.z)) < 0.511);
            if (isHere[k]) lights[k].w -= 1;
            #if SMOOTH_LIGHTING == 2
            lights[k].w *= isHere[k] ? 1 : intMult0;
            #elif SMOOTH_LIGHTING == 1
            lights[k].w = - abs(lightDir.x) - abs(lightDir.y) - abs(lightDir.z);
            #endif
            ndotls[k] = (isHere[k] || calcNdotLs) ? 1 : max(0, dot(normalize(lightDir), normal));
        }

        ndotls = min(ndotls * 2, 1);
        vec3[3] lightCols;
        ivec3 lightMats;
        for (int k = 0; k < 3; k++) {
            vxData lightSourceData = readVxMap(getVxPixelCoords(vxPos + lights[k].xyz));
            lightCols[k] = lightSourceData.lightcol * (lightSourceData.emissive ? 1.0 : 0.0);
            lightMats[k] = lightSourceData.mat;
            #if SMOOTH_LIGHTING == 1
            lights[k].w = max(lights[k].w + lightSourceData.lightlevel, 0.0);
            #endif
        }
        #if SMOOTH_LIGHTING == 2
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
                    if (length(vec3(lights[i0].xyz - cornerLights[j].xyz - offset * offsetDir)) < (cornerLightMat == lightMats[i0] ? 1.5 : 0.5)) {
                        lights[i0].w += cornerLights[j].w * intMult * (isHere[i0] ? 0 : 1);
                        break;
                    }
                }
            }
        }
        #endif
        vec3 occlusionData = getOcclusion(vxPosOld, normal);
        for (int k = 0; k < 3; k++) lightCol += lightCols[k] * occlusionData[k] * pow(lights[k].w * BLOCKLIGHT_STRENGTH / 20.0, BLOCKLIGHT_STEEPNESS) * ndotls[k];
        return lightCol;
    } else return vec3(0);
}

vec3 getBlockLight(vec3 vxPos) {
    return getBlockLight(vxPos, vec3(0));
}
#ifdef SUN_SHADOWS
float getSunOcclusion(vec3 vxPos) {
    int k = 0;
    // zoom in appropriately
    for (; isInRange(2 * vxPos, 1) && k < OCCLUSION_CASCADE_COUNT - 1; k++) {
        vxPos *= 2;
    }
    float occlusion = 0;
    #if OCCLUSION_FILTER > 0
    vxPos -= 0.5;
    vec3 floorPos = floor(vxPos);
    float totalInt = 1; // track total intensity
    for (int j = 0; j < 8; j++) {
        vec3 offset = vec3(j%2, (j>>1)%2, (j>>2)%2);
        vec3 cornerPos = floorPos + offset;
        // this corner's intensity multiplier
        float intMult = (1 - abs(vxPos.x - cornerPos.x)) * (1 - abs(vxPos.y - cornerPos.y)) * (1 - abs(vxPos.z - cornerPos.z));
        // skip this corner if it is across a block boundary, to disregard dark spots on the insides of surfaces
        if (length(floor(cornerPos / float(1 << k)) - floor((vxPos + 0.5) / float(1 << k))) > 0.5) {
            totalInt -= intMult;
            continue;
        }
        #else
        vec3 cornerPos = vxPos;
        float intMult = 1.0;
        #endif
        ivec4 sunData = ivec4(texelFetch(colortex10, getVxPixelCoords(cornerPos + 0.5), 0) * 65535 + 0.5);
        occlusion += ((k == 0) ? (sunData.x % 4 == SUN_CHECK_SPREAD ? 1 : 0) : ((sunData.x >> k + 3) % 2)) * intMult;
    #if OCCLUSION_FILTER > 0
    }
    occlusion /= totalInt;
    #endif
    return occlusion;
}

vec2[9] shadowoffsets = vec2[9](
    vec2( 0.0       ,  0.0),
    vec2( 0.47942554,  0.87758256),
    vec2( 0.95954963,  0.28153953),
    vec2( 0.87758256, -0.47942554),
    vec2( 0.28153953, -0.95954963),
    vec2(-0.47942554, -0.87758256),
    vec2(-0.95954963, -0.28153953),
    vec2(-0.87758256,  0.47942554),
    vec2(-0.28153953,  0.95954963)
);

vec3 getSunLight(vec3 vxPos, vec3 sunDir, vec3 normal) {
    vec2 tex8size0 = vec2(textureSize(colortex8, 0));
    vec3 shadowPos = getShadowPos(vxPos, sunDir);
    vec3 sunColor = vec3(0);
    #if OCCLUSION_FILTER > 0
    for (int k = 0; k < 9; k++) {
    #else
    int k = 0;
    #endif
        vec4 sunData = texture2D(colortex10, (shadowPos.xy * shadowMapResolution + shadowoffsets[k] * 0.9) / tex8size0);
        sunData.yz = (sunData.yz - 0.5) * 1.5 * vxRange;
        int sunColor0 = int(texelFetch(colortex10, ivec2(shadowPos.xy * shadowMapResolution + shadowoffsets[k] * 0.9), 0).r * 65535 + 0.5);
        vec3 sunColor1 = vec3(sunColor0 % 16, (sunColor0 >> 4) % 16, (sunColor0 >> 8) % 16)  * (sunColor0 >> 12) / 64.0 ;
        sunColor += shadowPos.z > sunData.y ? (shadowPos.z > sunData.z ? vec3(1) : sunColor1) : vec3(0.0);
    #if OCCLUSION_FILTER > 0
    }
    sunColor *= 0.2;
    #endif
    return sunColor;
    //return shadowPos;
}
#endif
#endif