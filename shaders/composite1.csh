#version 430

const vec2 workGroupsRender = vec2(1.0, 1.0);

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(r32ui) uniform uimage3D voxelImg;
#include "/lib/ssbo.glsl"

uniform int frameCounter;
uniform float viewWidth, viewHeight;
uniform vec3 cameraPositionFract;
uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
layout(r32ui) uniform uimage2D colorimg3;
layout(rgba16f) uniform image2D colorimg4;
layout(rgba16f) uniform image2D colorimg0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex1;

#include "/lib/random.glsl"
#include "/lib/raytrace.glsl"

shared uint lightLocs[MAX_LIGHT_COUNT];
shared uint lightVisibilities[MAX_LIGHT_COUNT];
shared uint lightHashMap[128];
shared vec3 cornerVoxelPos[4];
shared vec3 cornerNormal[4];

shared int lightCount;
shared uint totalLightVisibility;

void main() {
    generateSeed(ivec2(gl_GlobalInvocationID.xy), frameCounter);
    ivec2 writeCoord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 screenCoord = ivec2(writeCoord / workGroupsRender + 0.5);
    int index = int(gl_LocalInvocationIndex);
    vec4 screenPos = vec4(screenCoord / vec2(viewWidth, viewHeight), texelFetch(depthtex1, screenCoord, 0).r, 1.0);
    vec3 normal = texelFetch(colortex1, screenCoord, 0).xyz * 2.0 - 1.0;
    vec4 playerPos = gbufferModelViewInverse * gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    playerPos /= playerPos.w;
    vec3 voxelPos = playerPos.xyz + cameraPositionFract + VOXEL_DIST;
    vec3 biasedVoxelPos = voxelPos + 0.05 * normal;
    if (index < 4) {
        ivec2 cornerCoord = ivec2((
            ivec2(gl_WorkGroupSize.xy * gl_WorkGroupID.xy) +
            (ivec2(gl_WorkGroupSize.xy) - 1) * ivec2(index%2, index/2)
        ) / workGroupsRender + 0.5);
        vec4 cornerScreenPos = vec4(cornerCoord / vec2(viewWidth, viewHeight), texelFetch(depthtex1, cornerCoord, 0).r, 1.0);
        cornerNormal[index] = texelFetch(colortex1, screenCoord, 0).xyz * 2.0 - 1.0;
        vec4 cornerPlayerPos = gbufferModelViewInverse * gbufferProjectionInverse * (cornerScreenPos * 2.0 - 1.0);
        cornerPlayerPos /= cornerPlayerPos.w;
        cornerVoxelPos[index] = cornerPlayerPos.xyz + cameraPositionFract + VOXEL_DIST + 0.1 * cornerNormal[index];

    }
    if (index == 0) {
        lightCount = 0;
        totalLightVisibility;
    }
    if (index < MAX_LIGHT_COUNT) {
        lightHashMap[index] = 0u;
        lightVisibilities[index] = 0u;
    }
    memoryBarrierShared();
    barrier();

    for (int lightReadIndex = 0; lightReadIndex < 5; lightReadIndex++) {
        ivec2 lightReadCoord =
            writeCoord +
            int(lightReadIndex != 0) *
            (lightReadIndex/2*2-1) *
            ((lightReadIndex + ivec2(0, 1))%2) *
            ivec2(gl_WorkGroupSize.xy);
        if (
            any(lessThan(lightReadCoord, ivec2(0))) ||
            any(greaterThanEqual(lightReadCoord, ivec2(viewWidth, viewHeight)))
        ) continue;
        uint prevLight = imageLoad(colorimg3, lightReadCoord).r;
        if (prevLight == 0u) continue;
        ivec3 prevLightPos = ivec3(
            prevLight & (1u<<11)-1u,
            prevLight >> 11 & (1u<<10)-1u,
            prevLight >> 21
        ) + (previousCameraPositionInt - cameraPositionInt);
        uint lightHash = posHash(prevLightPos) % (128 * 32);
        ivec3 subIndex = prevLightPos%2;
        int bitOffset = 4 * (subIndex.x + subIndex.y * 2 + subIndex.z * 4) + 3;
        if (
            any(lessThan(prevLightPos, ivec3(0))) ||
            any(greaterThanEqual(prevLightPos, ivec3(2 * VOXEL_DIST))) ||
            (lightHashMap[lightHash/32] & 1<<lightHash%32) != 0 ||
            (imageLoad(voxelImg, prevLightPos/2).r & (1u<<bitOffset)) == 0u
        ) continue;
        light_t unpackedPrevLight = unpackLightData(lightArray[posHash(prevLightPos)%1000000u]);
        vec3 lightPos = prevLightPos + unpackedPrevLight.relPos - 1.0;
        bool visible = false;
        for (int cornerIndex = 0; cornerIndex < 4; cornerIndex++) {
            vec3 thisVxPos = cornerVoxelPos[cornerIndex];
            if (
                thisVxPos == clamp(thisVxPos, 0.0, 2.0 * VOXEL_DIST) &&
                dot(lightPos - thisVxPos, cornerNormal[cornerIndex]) > -1000.5
            ) {
                vec3 hitPos = hybridRT(thisVxPos, lightPos - thisVxPos);
                if (length(hitPos - thisVxPos) > length(lightPos - thisVxPos) - 100.5) {
                    visible = true;
                    break;
                }
            }
        }
        if (visible) {
            if ((atomicOr(lightHashMap[lightHash/32], 1u<<lightHash%32) & 1u<<lightHash%32) == 0u) {
                int lightIndex = atomicAdd(lightCount, 1);
                if (lightIndex < MAX_LIGHT_COUNT) {
                    uint offsetPrevLight =
                        uint(prevLightPos.x) +
                        (uint(prevLightPos.y) << 11) +
                        (uint(prevLightPos.z) << 21);
                    lightLocs[lightIndex] = offsetPrevLight;
                }
            }
        }
    }
    if (nextFloat() < LIGHT_DISCOVERY_RATE && screenPos.z < 0.9999) {
        vec3 dir = randomCosineWeightedHemisphereSample(normal);
        vec3 hitNormal;
        bool hitEmission = true;
        vec3 hitPos = voxelRT(biasedVoxelPos, LIGHT_TRACE_LENGTH * dir, hitNormal, hitEmission);
        if (hitEmission) {
            ivec3 hitCoords = ivec3(hitPos - 0.2 * abs(hitNormal));
            vec3 confirmation = hybridRT(biasedVoxelPos, hitPos - biasedVoxelPos);
            if (length(confirmation - biasedVoxelPos) > length(hitPos - biasedVoxelPos) - 2.0) {
                uint hitHash = posHash(hitCoords) % (128 * 32);
                if ((atomicOr(lightHashMap[hitHash/32], 1u<<hitHash%32) & 1u<<hitHash%32) == 0) {
                    int lightIndex = atomicAdd(lightCount, 1);
                    if (lightIndex < MAX_LIGHT_COUNT) {
                        uint packedPos = hitCoords.x | hitCoords.y << 11 | hitCoords.z << 21;
                        lightLocs[lightIndex] = packedPos;
                    }
                }
            }
        }
    }
    memoryBarrierShared();
    barrier();
    vec3 blockLight = vec3(0.0);
    if (screenPos.z < 0.9999) {
        for (int k = 0; k < min(MAX_LIGHT_COUNT, lightCount); k++) {
            ivec3 lightCoords = ivec3(
                lightLocs[k]     & (1u<<11)-1u,
                lightLocs[k]>>11 & (1u<<10)-1u,
                lightLocs[k]>>21
            );
            uint lightHash = posHash(lightCoords) % 1000000;
            light_t light = unpackLightData(lightArray[lightHash]);
            vec3 lightPos = lightCoords + light.relPos;
            vec3 lightDir = lightPos - voxelPos;
            float ndotl = dot(normal, normalize(lightDir));
            float dirLen = length(lightDir);
            if (ndotl > 0.0 && dirLen < LIGHT_TRACE_LENGTH * light.brightness) {
                vec3 hitPos = lightPos;
                vec3 rtDir = lightPos + randomSphereSample() * 0.1 - biasedVoxelPos;
                hitPos = hybridRT(biasedVoxelPos, rtDir);
                bool visible = (
                    floor(mix(hitPos, lightPos, 0.01)) == floor(lightPos) ||
                    length(hitPos - voxelPos) >= dirLen - 0.5
                );
                if (visible) {
                    vec3 thisLight = light.col * light.brightness * ndotl * 2.0 / (dirLen * dirLen + 0.1);
                    blockLight += thisLight;
                    int visibilityAddend = int((100.0 + nextFloat()) * length(thisLight));
                    atomicAdd(lightVisibilities[k], visibilityAddend);
                    atomicAdd(totalLightVisibility, visibilityAddend);
                }
                if (!(hitPos == hitPos)) {
                    blockLight = vec3(1.0, 0.0, 1.0);
                }
            }
        }
    }
    float lBlockLight = length(blockLight);
    if (lBlockLight > 0.01) {
        blockLight *= log(lBlockLight + 1) / lBlockLight;
    }
    imageStore(colorimg4, writeCoord, vec4(blockLight, 1.0));
    memoryBarrierShared();
    barrier();
    uint lightToStore = 0u;
    float visibilityFactor = LIGHT_RETENTION_RATE * float(lightVisibilities[index]) / float(totalLightVisibility);
    if (index < min(lightCount, MAX_LIGHT_COUNT) && nextFloat() < visibilityFactor) {
        lightToStore = lightLocs[index];
    }
    imageStore(colorimg3, writeCoord, uvec4(lightToStore));
}