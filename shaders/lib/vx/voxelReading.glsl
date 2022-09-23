#define READING
#if !defined MAPPING && defined TEX89
#include "/lib/vx/voxelMapping.glsl"
#endif

struct vxData {
    vec2 texcoord;
    vec3 lower;
    vec3 upper;
    int mat;
    int lightlevel;
    float spritesize;
    vec3 lightcol;
    bool trace;
    bool full;
    bool cuboid;
    bool alphatest;
    bool emissive;
    bool crossmodel;
};

vxData readVxMap(vec2 coords) {
    ivec4 data0 = ivec4(texture2D(shadowcolor0, coords) * 65535 + 0.5);
    ivec4 data1 = ivec4(texture2D(shadowcolor1, coords) * 65535 + 0.5);
    vxData data;
    if (data0.w == 65535) {
        data.lightcol = vec3(0);
        data.texcoord = vec2(-1);
        data.mat = -1;
        data.lower = vec3(0);
        data.upper = vec3(1);
        data.full = false;
        data.cuboid = false;
        data.alphatest = false;
        data.trace = false;
        data.emissive = false;
        data.crossmodel = false;
        data.spritesize = 0;
        data.lightlevel = 0;
    } else {
        data.lightcol = vec3(data0.x % 256, data0.x / 256, data0.y % 256) / 255;
        data.texcoord = vec2(16 * (data0.y / 256) + data0.z % 16, data0.z / 16) / 4095;
        data.mat = data0.w;
        data.lower = vec3(data1.x % 16, (data1.x / 16) % 16, (data1.x / 256) % 16) / 16.0;
        data.upper = vec3((data1.x / 4096) % 16, data1.y % 16, (data1.y / 16) % 16) / 16.0;
        int type = data1.y / 256;
        data.full = ((type / 4) % 2 == 1);
        data.cuboid = ((type / 16) % 2 == 1);
        data.alphatest = (type % 2 == 1);
        data.trace = ((type / 32) % 2 == 0 && data0.w != 65535);
        data.emissive = ((type / 8) % 2 == 1);
        data.crossmodel = ((type / 2) % 2 == 1);
        data.spritesize = pow(2, data1.z % 16);
        data.lightlevel = (data1.z / 16) % 128;
    }
    return data;
}

#ifdef TEX89
vec2 tex8size0 = vec2(textureSize(colortex8, 0));

vec3 getOcclusion(vec3 vxPos) {
    int k = 0;
    for (; isInRange(2 * vxPos, 1) && k < 4; k++) {
        vxPos *= 2;
    }
    vec3 occlusion = vec3(0);
    vxPos -= 0.5;
    vec3 floorPos = floor(vxPos);
    float totalInt = 1;
    for (int j = 0; j < 8; j++) {
        vec3 offset = vec3(j%2, (j>>1)%2, (j>>2)%2);
        vec3 cornerPos = floorPos + offset;
        float intMult = (1 - abs(vxPos.x - cornerPos.x)) * (1 - abs(vxPos.y - cornerPos.y)) * (1 - abs(vxPos.z - cornerPos.z));
        if (length(floor(cornerPos / (1 << k)) - floor((vxPos + 0.5) / (1 << k))) > 0.5) {
            totalInt -= intMult;
            continue;
        }
        ivec4 lightData = ivec4(texture2D(colortex8, getVxCoords(cornerPos + 0.5) * shadowMapResolution / tex8size0) * 65535 + 0.5);        for (int i = 0; i < 3; i++) occlusion[i] += ((lightData.y >> 3 * k + i) % 2) * intMult;
    }
    occlusion /= totalInt;
    return occlusion;
}
vec3 getBlockLight(vec3 vxPos, vec3 normal) {
    vec3 lightCol = vec3(0);
    vec3 vxPosOld = vxPos + floor(cameraPosition) - floor(previousCameraPosition);
    vec3 referencePos = vxPosOld - 0.5;
    if (isInRange(vxPosOld) && isInRange(vxPos)) {
        vec2 vxCoordsFF = getVxCoords(vxPosOld) * shadowMapResolution / tex8size0;
        vec2 vxCoordsFFlower = getVxCoords(vxPosOld - vec3(0.5)) * shadowMapResolution / tex8size0;
        ivec4 lightData0 = ivec4(texture2D(colortex8, vxCoordsFF) * 65535 + 0.5);
        ivec4 lightData1 = (lightData0.w >> 8 > 0) ? ivec4(texture2D(colortex9, vxCoordsFF) * 65535 + 0.5) : ivec4(0);
        ivec4 lightData0Lower = ivec4(texture2D(colortex8, vxCoordsFFlower) * 65535 + 0.5);
        ivec4 lightData1Lower = (lightData0Lower.w >> 8 > 0) ? ivec4(texture2D(colortex9, vxCoordsFFlower) * 65535 + 0.5) : ivec4(0);
        vec3 occlusionData = getOcclusion(vxPosOld);
        
        float intMult = (1 - abs(fract(vxPos.x) - 0.5)) * (1 - abs(fract(vxPos.y) - 0.5)) * (1 - abs(fract(vxPos.z) - 0.5));
        vec4[3] lights = vec4[3](
            vec4(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256, (lightData0.w >> 8) * intMult * occlusionData.x) - vec4(128, 128, 128, 0),
            vec4(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256, (lightData1.y >> 8) * intMult * occlusionData.y) - vec4(128, 128, 128, 0),
            vec4(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256, (lightData1.w >> 8) * intMult * occlusionData.z) - vec4(128, 128, 128, 0)
        );
        vec3 ndotls;
        if (normal == vec3(0)) ndotls = vec3(1);
        else {
            for (int k = 0; k < 3; k++) {
                vec3 lightDir = lights[k].xyz + 0.5 - fract(vxPos);
                ndotls[k] = max(max(abs(lightDir.x), abs(lightDir.y)), abs(lightDir.z)) < 0.52 ? 1 : max(0, dot(normalize(lightDir), normal));
            }
            ndotls = min(ndotls * 2, 1);
        }
/*
        vec4[3] lightslll = isInRange(vxPosOld - vec3(1)) ? vec4[3](
            vec4(lightData0Lower.z % 256, lightData0Lower.z >> 8, lightData0Lower.w % 256, 0) - vec4(128, 128, 128, 0),
            vec4(lightData1Lower.x % 256, lightData1Lower.x >> 8, lightData1Lower.y % 256, 0) - vec4(128, 128, 128, 0),
            vec4(lightData1Lower.z % 256, lightData1Lower.z >> 8, lightData1Lower.w % 256, 0) - vec4(128, 128, 128, 0)
        ) : lights;
*/
        vec3[3] lightCols;
        for (int k = 0; k < 3; k++) {
            /*bool present = false;
            for (int i = 0; i < 3; i++) if (length(lightslll[i] - lights[k]) < 0.5) present = true;
            if (!present) lights[k].w = 0;*/
            vxData lightSourceData = readVxMap(getVxCoords(vxPos + lights[k].xyz));
            lightCols[k] = lightSourceData.lightcol;
        }
        vec3 offsetDir = sign(fract(vxPos) - 0.5);
        vec3 floorPos = floor(vxPosOld);
        for (int k = 1; k < 8; k++) {
            vec3 offset = vec3(k%2, (k>>1)%2, (k>>2)%2);
            vec3 cornerPos = floorPos + offset * offsetDir + 0.5;
            if (!isInRange(cornerPos)) continue;
            intMult = (1 - abs(cornerPos.x - vxPosOld.x)) * (1 - abs(cornerPos.y - vxPosOld.y)) * (1 - abs(cornerPos.z - vxPosOld.z));
            vec2 cornerVxCoordsFF = getVxCoords(cornerPos) * shadowMapResolution / tex8size0;
            ivec4 cornerLightData0 = ivec4(texture2D(colortex8, cornerVxCoordsFF) * 65535 + 0.5);
            ivec4 cornerLightData1 = (cornerLightData0.w >> 8 > 0) ? ivec4(texture2D(colortex9, cornerVxCoordsFF) * 65535 + 0.5) : ivec4(0);
            vec4[3] cornerLights = vec4[3](
                vec4(cornerLightData0.z % 256, cornerLightData0.z >> 8, cornerLightData0.w % 256, (cornerLightData0.w >> 8)) - vec4(128, 128, 128, 0),
                vec4(cornerLightData1.x % 256, cornerLightData1.x >> 8, cornerLightData1.y % 256, (cornerLightData1.y >> 8)) - vec4(128, 128, 128, 0),
                vec4(cornerLightData1.z % 256, cornerLightData1.z >> 8, cornerLightData1.w % 256, (cornerLightData1.w >> 8)) - vec4(128, 128, 128, 0)
            );
            for (int j = 0; j < 3 && cornerLights[j].w > 0; j++) {
                for (int i = 0; i < 3; i++) {
                    if (length(lights[i].xyz - cornerLights[j].xyz - offset * offsetDir) < 0.5) {
                        lights[i].w += cornerLights[j].w * occlusionData[i] * intMult;
                        break;
                    }
                }
            }
        }
        for (int k = 0; k < 3; k++) lightCol += lightCols[k] * pow(lights[k].w * BLOCKLIGHT_STRENGTH / 20.0, BLOCKLIGHT_STEEPNESS) * ndotls[k];
    }
    return lightCol;
}

vec3 getBlockLight(vec3 vxPos) {
    return getBlockLight(vxPos, vec3(0));
}
#endif