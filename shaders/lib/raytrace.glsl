#ifndef INCLUDE_RAYTRACE
#define INCLUDE_RAYTRACE

#include "/lib/voxel_settings.glsl"
#define MAX_RT_STEPS 2000

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
                emissive = ((thisVoxelData & 1u << voxelDataOffset + 3) != 0)
                normal *= -dirSgn;
                return thisPos;
            }
        }
        progress += normal * invDir;
    }
    normal = -normalize(dir);
    return start + 2.0 * dir;
}
#endif //INCLUDE_RAYTRACE