#ifndef INCLUDE_RAYTRACE
#define INCLUDE_RAYTRACE

#include "/lib/common_functions.glsl"

#include "/lib/voxel_settings.glsl"
#define MAX_RT_STEPS 2000

// in voxel space (player space + cameraPositionFract)
vec3 voxelRT(vec3 start, vec3 dir, out vec3 normal, out bool emissive) {
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
            if ((thisVoxelData & (1u << normalDir | 1u << 3) << voxelDataOffset) != 0u) {
                emissive = ((thisVoxelData & 1u << voxelDataOffset + 3) != 0);
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

// also in voxel space
vec3 ssRT(vec3 start, vec3 dir) {
    vec3 playerStart = start - cameraPositionFract - VOXEL_DIST;
    float startBehind = 0.5 + dot(playerStart, gbufferModelViewInverse[2].xyz);
    if (startBehind > 0.0) {
        playerStart -= min(0.0, startBehind / dot(dir, gbufferModelViewInverse[2].xyz)) * dir;
    }
    vec4 screenStart = gbufferProjection * gbufferModelView * vec4(playerStart, 1.0);
    screenStart /= screenStart.w;
    vec4 screenEnd = gbufferProjection * gbufferModelView * vec4(playerStart + dir, 1.0);
    screenEnd /= screenEnd.w;
    screenStart = 0.5 * screenStart + 0.5;
    screenEnd = 0.5 * screenEnd + 0.5;

    bool wasEverOnScreen = false;
    vec3 screenVec = screenEnd.xyz - screenStart.xyz;
    float screenDist = infnorm(vec2(viewWidth, viewHeight) * screenVec.xy);
    vec3 screenPos = screenStart.xyz;
    float stepSize = min(0.3, 10.0 / screenDist);
    float prevZDiff = 0.0;
    for (int k = 0; k < 100; k++) {
        if (clamp(screenPos, 0.0, 1.0) == screenPos) {
            wasEverOnScreen = true;
        } else if (wasEverOnScreen) {
            break;
        }
        float z = textureLod(depthtex1, screenPos.xy, 0).x;
        if (prevZDiff * (z - screenPos.z) < 0.0) {
            stepSize *= -0.3;
            if (abs(stepSize) < 0.25 / screenDist) {
                if (
                    !isEdge(screenPos.xy) &&
                    abs(z - screenStart.z) < abs(screenVec.z) &&
                    abs(z - screenPos.z) < 0.001
                ) {
                    vec4 thisPlayerPos = gbufferModelViewInverse * gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
                    return thisPlayerPos.xyz / thisPlayerPos.w + cameraPositionFract + VOXEL_DIST;
                } else {
                    stepSize = min(10.0 / screenDist, 0.3);
                    prevZDiff = 0.0;
                    screenPos += screenVec * stepSize;
                    continue;
                }
            }
        }
        if (wasEverOnScreen) prevZDiff = z - screenPos.z;
        screenPos += screenVec * stepSize;
    }
    return start + 2 * dir;
}

vec3 hybridRT(vec3 start, vec3 dir) {
    vec3 normal;
    bool emissive;
    vec3 hitPos = ssRT(start, dir);
    if (length(hitPos - start) > length(dir)) {
        hitPos = voxelRT(start, dir, normal, emissive);
    }
    return hitPos;
}

#endif //INCLUDE_RAYTRACE