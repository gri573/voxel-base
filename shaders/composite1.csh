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
shared bool lightVisibilities[MAX_LIGHT_COUNT];
shared bool skipTrace[MAX_LIGHT_COUNT];
shared uint lightHashMap[128];

shared int lightCount;

void main() {
    generateSeed(ivec2(gl_GlobalInvocationID.xy), frameCounter);
    ivec2 writeCoord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 screenCoord = ivec2(writeCoord / workGroupsRender);
    int index = int(gl_LocalInvocationIndex);

    if (index == 0) {
        lightCount = 0;
    }
    if (index < MAX_LIGHT_COUNT) {
        lightHashMap[index] = 0u;
        lightVisibilities[index] = false;
    }
    memoryBarrierShared();
    barrier();

    uint prevLight = imageLoad(colorimg3, writeCoord).r;
    if (prevLight != 0u) {
        ivec3 prevLightPos = ivec3(
            prevLight & (1u<<11)-1u,
            prevLight >> 11 & (1u<<10)-1u,
            prevLight >> 21
        ) + (previousCameraPositionInt - cameraPositionInt);
        if (
            all(greaterThanEqual(prevLightPos, ivec3(0))) &&
            all(lessThan(prevLightPos, ivec3(2 * VOXEL_DIST)))
        ) {
            ivec3 subIndex = prevLightPos%2;
            uint lightHash = posHash(prevLightPos) % (128 * 32);
            int bitOffset = 4 * (subIndex.x + subIndex.y * 2 + subIndex.z * 4) + 3;
            if ((imageLoad(voxelImg, prevLightPos/2).r & (1u<<bitOffset)) != 0u) {
                imageStore(colorimg0, writeCoord, vec4(1, 0, 1, 1));
                if ((atomicOr(lightHashMap[lightHash/32], 1u<<lightHash%32) & 1<<lightHash%32) == 0u) {
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
    }
    vec4 screenPos = vec4(screenCoord / vec2(viewWidth, viewHeight), texelFetch(depthtex1, screenCoord, 0).r, 1.0);
    vec3 normal = texelFetch(colortex1, screenCoord, 0).xyz * 2.0 - 1.0;
    vec4 playerPos = gbufferModelViewInverse * gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    playerPos /= playerPos.w;
    vec3 voxelPos = playerPos.xyz + cameraPositionFract + VOXEL_DIST;
    vec3 biasedVoxelPos = voxelPos + 0.03 * normal;
    if (screenPos.z < 0.9999) {
        vec3 dir = randomCosineWeightedHemisphereSample(normal);
        vec3 hitNormal;
        bool hitEmission = true;
        vec3 startOffset = vec3(nextFloat(), nextFloat(), nextFloat()) * 2.0 - 1.0 + normal;
        vec3 hitPos = voxelRT(biasedVoxelPos + startOffset, 30.0 * dir, hitNormal, hitEmission);
        if (hitEmission) {
            ivec3 hitCoords = ivec3(hitPos - 0.5 * abs(hitNormal));
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
            vec3 lightDir = lightCoords + light.relPos - voxelPos;
            float ndotl = dot(normal, normalize(lightDir));
            float dirLen = length(lightDir);
            if (ndotl > 0.0 && dirLen < 30) {
                vec3 lightPos = voxelPos + lightDir;
                vec3 rtDir = lightPos + randomSphereSample() * 0.1 - biasedVoxelPos;
                vec3 hitPos = hybridRT(biasedVoxelPos, rtDir);
                if (
                    floor(mix(hitPos, lightPos, 0.05)) == floor(lightPos) ||
                    length(hitPos - voxelPos) >= dirLen - 0.5
                ) {
                    blockLight += light.col * ndotl * 2.0 / (dirLen * dirLen + 0.1);
                    lightVisibilities[k] = true;
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
    if (index < min(lightCount, MAX_LIGHT_COUNT) && lightVisibilities[index]) {
        lightToStore = lightLocs[index];
    }
    imageStore(colorimg3, writeCoord, uvec4(lightToStore));
}