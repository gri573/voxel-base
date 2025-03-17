#version 430

const vec2 workGroupsRender = vec2(1.0, 1.0);

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(r32ui) uniform uimage3D voxelImg;
#include "/lib/ssbo.glsl"

uniform int frameCounter;
uniform float viewWidth, viewHeight;
uniform vec3 cameraPositionFract;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
layout(rgba8) uniform image2D colorimg0;
uniform sampler2D colortex1;
uniform sampler2D depthtex1;

#include "/lib/raytrace.glsl"
#include "/lib/random.glsl"

shared uint lightLocs[128];
shared uint lightHashMap[128];

shared int lightCount;

void main() {
    generateSeed(ivec2(gl_GlobalInvocationID.xy), frameCounter);
    ivec2 screenCoord = ivec2(gl_GlobalInvocationID.xy / workGroupsRender + 0.5);
    int index = int(gl_LocalInvocationIndex);

    if (index == 0) {
        lightCount = 0;
    }
    if (index < 128) {
        lightHashMap[index] = 0u;
    }
    memoryBarrierShared();
    barrier();
    vec4 screenPos = vec4(screenCoord / vec2(viewWidth, viewHeight), texelFetch(depthtex1, screenCoord, 0).r, 1.0);
    vec3 normal = texelFetch(colortex1, screenCoord, 0).xyz * 2.0 - 1.0;
    vec4 playerPos = gbufferModelViewInverse * gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    playerPos /= playerPos.w;
    vec3 voxelPos = playerPos.xyz + cameraPositionFract + VOXEL_DIST;
    voxelPos += 0.1 * normal;
    if (screenPos.z < 0.9999) {
        vec3 dir = randomCosineWeightedHemisphereSample(normal);
        vec3 hitNormal;
        bool hitEmission = true;
        vec3 hitPos = voxelRT(voxelPos, 30.0 * dir, hitNormal, hitEmission);
        if (hitEmission) {
            ivec3 hitCoords = ivec3(hitPos - 0.5 * abs(hitNormal));
            uint hitHash = posHash(hitCoords) % (128 * 32);
            if ((atomicOr(lightHashMap[hitHash/32], 1u<<hitHash%32) & 1u<<hitHash%32) == 0) {
                int lightIndex = atomicAdd(lightCount, 1);
                if (lightIndex < 128) {
                    uint packedPos = hitCoords.x | hitCoords.y << 11 | hitCoords.z << 21;
                    lightHashMap[lightIndex] = packedPos;
                }
            }
        }
    }
    memoryBarrierShared();
    barrier();
    vec3 blockLight = vec3(0.0);
    if (screenPos.z < 0.9999) {
        for (int k = 0; k < min(128, lightCount); k++) {
            ivec3 lightCoords = ivec3(
                lightHashMap[k]     & (1u<<11)-1,
                lightHashMap[k]>>11 & (1u<<10)-1,
                lightHashMap[k]>>21
            );
            uint lightHash = posHash(lightCoords) % 1000000;
            light_t light = unpackLightData(lightArray[lightHash]);
            vec3 lightDir = lightCoords + light.relPos - voxelPos;
            float ndotl = dot(normal, lightDir);
            float dirLen = length(lightDir) - 0.5;
            if (ndotl > 0.0 && dirLen < 30) {
                lightDir += randomSphereSample() * 0.1;
                vec3 hitPos = hybridRT(voxelPos, lightDir);
                if (length(hitPos - voxelPos) >= dirLen) {
                    blockLight += light.col * ndotl * 2.0 / (dirLen * dirLen + 0.1);
                }
            }
        }
    }
    float lBlockLight = length(blockLight);
    if (lBlockLight > 0.01) {
        blockLight *= log(lBlockLight + 1) / lBlockLight;
    }
    imageStore(colorimg0, screenCoord, vec4(blockLight, 1.0));
}