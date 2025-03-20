#ifndef INCLUDE_RAYTRACE
#define INCLUDE_RAYTRACE

#include "/lib/common_functions.glsl"

#include "/lib/voxel_settings.glsl"
#define MAX_RT_STEPS 2000
//#define DO_VOXEL_RT

mat4 projModView = gbufferProjection * gbufferModelView;
mat4 projModViewInv = gbufferModelViewInverse * gbufferProjectionInverse;

// in voxel space (player space + cameraPositionFract)
vec3 voxelRT(vec3 start, vec3 dir, out vec3 normal, inout bool emissive) {
    uint emissiveMask = uint(emissive) << 3;
    emissive = false;

    dir += 1e-10 * vec3(equal(dir, vec3(0)));
    vec3 dirSgn = sign(dir);
    float dirLen = length(dir);
    vec3 invDir = 1.0/abs(dir);
    vec3 progress = (0.5 + 0.5 * dirSgn - fract(start)) * invDir * dirSgn;
    float w = 1e-5;
    normal = vec3(0);
    for (int k = 0; k < MAX_RT_STEPS; k++) {
        w = min(min(progress.x, progress.y), progress.z);
        normal = vec3(equal(progress, vec3(w)));
        vec3 thisPos = start + w * dir;
        ivec3 thisCoord = ivec3(thisPos - 0.5 * normal);
        if (any(greaterThanEqual(thisCoord, ivec3(2 * VOXEL_DIST))) || any(lessThan(thisCoord, ivec3(0))) || w > 1.0) {
            break;
        }
        uint thisVoxelData = imageLoad(voxelImg, thisCoord / 2).r;

        if (thisVoxelData != 0u) { // handle inner part of voxel
            ivec3 localCoord = thisCoord % 2;
            int voxelDataOffset = 4 * (localCoord.x + 2 * localCoord.y + 4 * localCoord.z);
            int normalDir = int(dot(normal, vec3(0.5, 1.5, 2.5)));
            if ((thisVoxelData & (1u << normalDir | emissiveMask) << voxelDataOffset) != 0u) {
                emissive = ((thisVoxelData & emissiveMask << voxelDataOffset) != 0);
                normal *= -dirSgn;
                return thisPos;
            }
        }
        progress += normal * invDir;
    }
    normal = -normalize(dir);
    return start + 2.0 * dir;
}

bool isEdge(vec2 pos) {
    ivec2 coord = ivec2(pos * vec2(viewWidth, viewHeight));
    float laplace = -4.0 * texelFetch(depthtex1, coord, 0).r;
    vec2 grad = vec2(0.0);
    for (int k = 0; k < 4; k++) {
        ivec2 offset = (k/2*2-1) * ivec2(k%2, (k+1)%2);
        float depthVal = texelFetch(depthtex1, coord + offset, 0).r;
        laplace += depthVal;
        grad += offset * depthVal;
    }
    return laplace > 0.1 * length(grad);
}

vec3 coarseSSRT(vec3 start, vec3 dir, float dither) {
    const int stepCount = 10;
    for (int k = 0; k < stepCount; k++) {
        vec3 thisPos = start + (k + dither) * (1.0/stepCount) * dir;
        if (thisPos != clamp(thisPos, 0.0, 1.0)) break;
        float depthLeniency = 3.0 * (1.0 - thisPos.z) * (1.0 - thisPos.z);
        float z = textureLod(depthtex1, thisPos.xy, 0).r;
        if (
            (
                //(thisPos.z - z) * (start.z + max(k - 1 + dither, 0.0) * (1.0/stepCount) * dir.z - z) < 0.0 ||
                abs(thisPos.z - z - 0.8 * depthLeniency) < depthLeniency
            ) && !isEdge(thisPos.xy)
        ) {
            return vec3(thisPos.xy, z);
        }
    }
    return start + 20 * dir;
}

// also in voxel space
vec3 ssRT(vec3 start, vec3 dir, out vec3 normal) {
    normal = vec3(0);
    float dither = nextFloat();
    vec3 dir0 = dir;
    vec3 playerStart = start - cameraPositionFract - VOXEL_DIST;
    float linearDepthTraversal = dot(dir, gbufferModelViewInverse[2].xyz);
    float startBehind = 0.5 + dot(playerStart, gbufferModelViewInverse[2].xyz);
    if (startBehind > 0.0) {
        float offsetAmount = max(0.0, -startBehind / linearDepthTraversal);
        playerStart += offsetAmount * dir;
        dir *= 1.0 - offsetAmount;
        linearDepthTraversal *= 1.0 - offsetAmount;
    }
    float endBehind = startBehind + linearDepthTraversal;
    if (endBehind > 0.0) {
        float offsetAmount = max(0.0, endBehind / linearDepthTraversal);
        dir *= 1.0 - offsetAmount;
    }
    vec4 screenStart = projModView * vec4(playerStart, 1.0);
    screenStart /= screenStart.w;
    vec4 screenEnd = projModView * vec4(playerStart + dir, 1.0);
    screenEnd /= screenEnd.w;
    screenStart.xyz = 0.5 * screenStart.xyz + 0.5;
    screenEnd.xyz = 0.5 * screenEnd.xyz + 0.5;
    vec3 screenVec = screenEnd.xyz - screenStart.xyz;

    #ifndef FINE_SSRT
        vec3 screenHit = coarseSSRT(screenStart.xyz, screenVec, dither);
        normal = texture(colortex1, screenHit.xy).rgb * 2.0 - 1.0;
        vec4 playerHit = projModViewInv * vec4(screenHit * 2.0 - 1.0, 1.0);
        if (abs(screenHit.x - screenStart.x) > abs(screenVec.x)) {
            return start + 2 * dir0;
        }
        return playerHit.xyz / playerHit.w + cameraPositionFract + VOXEL_DIST;
    #endif

    bool wasEverOnScreen = false;
    screenVec /= infnorm(vec2(viewWidth, viewHeight) * screenVec.xy);
    vec3 screenPos = screenStart.xyz;
    const int maxLodLevel = 7;
    int lodLevel = 4;
    for (int k = 0; k < 100; k++) {
        if (clamp(screenPos, 0.0, 1.0) == screenPos) {
            wasEverOnScreen = true;
        } else if (wasEverOnScreen) {
            break;
        }
        if (wasEverOnScreen) {
            bool reducedLodLevel = false;
            while (lodLevel >= 2) {
                float nextZ = screenPos.z + screenVec.z * (1<<lodLevel);
                ivec2 lodCoord =
                    (ivec2(screenPos.xy * vec2(viewWidth, viewHeight)) >> lodLevel) +
                    ivec2(0, int(viewHeight + 0.5) * ((1<<lodLevel-1)-1) / (1<<lodLevel-1));
                vec2 zrange = texelFetch(colortex2, lodCoord, 0).xy;
                if (
                    zrange.x < max(nextZ, screenPos.z) &&
                    zrange.y > min(nextZ, screenPos.z)
                ) {
                    lodLevel --;
                    reducedLodLevel = true;
                } else {
                    break;
                }
            }
            if (!reducedLodLevel && k%7 == 3) {
                while (lodLevel < maxLodLevel-1) {
                    lodLevel++;
                    float nextZ = screenPos.z + screenVec.z * (1<<lodLevel);
                    ivec2 lodCoord =
                        (ivec2(screenPos.xy * vec2(viewWidth, viewHeight)) >> lodLevel) +
                        ivec2(0, int(viewHeight + 0.5) * ((1<<lodLevel-1)-1) / (1<<lodLevel-1));
                    vec2 zrange = texelFetch(colortex2, lodCoord, 0).xy;
                    if (
                        zrange.x < max(nextZ, screenPos.z) &&
                        zrange.y > min(nextZ, screenPos.z)
                    ) {
                        lodLevel--;
                        break;
                    }
                }
            }
            if (lodLevel < 2) {
                screenPos += dither * (1<<lodLevel) * screenVec;
                float leniency = 0.4 * ((1.0 - screenPos.z) * (1.0 - screenPos.z));
                float thisZDiff = textureLod(depthtex1, screenPos.xy, 0).r + 0.3 * leniency - screenPos.z;
                if (abs(thisZDiff) < leniency) {
                    normal = texture(colortex1, screenPos.xy).rgb * 2.0 - 1.0;
                    vec4 playerPos =
                        projModViewInv *
                        (vec4(screenPos, 1.0) * 2.0 - 1.0);
                    return playerPos.xyz / playerPos.w + cameraPositionFract + VOXEL_DIST;
                }
            }
        }
        screenPos += screenVec * (1<<lodLevel);
    }
    return start + 2.0 * dir0;
}

vec3 hybridRT(vec3 start, vec3 dir) {
    vec3 normal;
    bool emissive = false;
    vec3 hitPos = ssRT(start, dir, normal);
    #ifdef DO_VOXEL_RT
    if (length(hitPos - start) > length(dir))
        hitPos = voxelRT(start, dir, normal, emissive);
    else
    #endif //DO_VOXEL_RT
        hitPos -= 0.1 * normal;
    return hitPos;
}

#endif //INCLUDE_RAYTRACE