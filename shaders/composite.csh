#version 430

#include "/lib/voxel_settings.glsl"
#ifdef FINE_SSRT
const vec2 workGroupsRender = vec2(0.25, 0.25);
layout(local_size_x = 32, local_size_y = 32) in;

uniform sampler2D depthtex1;
layout(rg32f) uniform image2D colorimg2;

shared vec2[32][32] sharedDepth;
#else // FINE_SSRT
const ivec3 workGroups = ivec3(1, 1, 1);
layout(local_size_x = 1) in;
#endif // FINE_SSRT
void main() {
    #ifdef FINE_SSRT
    ivec2 viewSize = imageSize(colorimg2);
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    // first pass
    vec2[2][2] localDepths;
    for (int k = 0; k < 4; k++) {
        localDepths[k%2][k/2] = vec2(1.0, 0.0);
    }
    for (int k = 0; k < 16; k++) {
        ivec2 offset = ivec2(k%4, k/4);
        if (all(lessThan(4 * coord + offset, viewSize))) {
            float thisDepthVal = texelFetch(depthtex1, 4 * coord + offset, 0).r;
            localDepths[offset.x/2][offset.y/2].x = min(
                localDepths[offset.x/2][offset.y/2].x,
                thisDepthVal
            );
            localDepths[offset.x/2][offset.y/2].y = max(
                localDepths[offset.x/2][offset.y/2].y,
                thisDepthVal
            );
        }
    }

    vec2 thisThreadDepth = vec2(1.0, 0.0);

    for (int k = 0; k < 4; k++) {
        ivec2 offset = ivec2(k%2, k/2);
        vec2 thisDepth = localDepths[offset.x][offset.y];
        thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
        thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        if (all(lessThan(2 * coord + offset, viewSize/2))) {
            imageStore(
                colorimg2,
                2 * coord + offset,
                vec4(thisDepth, 0.0, 1.0)
            );
        }
    }

    sharedDepth[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = thisThreadDepth;
    if (all(lessThan(coord, viewSize/4))) {
        imageStore(colorimg2, coord + ivec2(0, viewSize.y/2), vec4(thisThreadDepth, 0.0, 1.0));
    }

    memoryBarrierShared();
    barrier();

    ivec2 localCoord = ivec2(gl_LocalInvocationID.xy);

    if (all(lessThan(localCoord, ivec2(16)))) {
        thisThreadDepth = vec2(1.0, 0.0);
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k%2, k/2);
            vec2 thisDepth = sharedDepth
                [2 * localCoord.x + offset.x]
                [2 * localCoord.y + offset.y];
            thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
            thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        }
    }

    barrier();
    if (all(lessThan(localCoord, ivec2(16)))) {
        sharedDepth[localCoord.x][localCoord.y] = thisThreadDepth;
        ivec2 writeCoord = 16 * ivec2(gl_WorkGroupID.xy) + localCoord;
        if (all(lessThan(writeCoord, viewSize / 8))) {
            writeCoord.y += viewSize.y * 3 / 4;
            imageStore(colorimg2, writeCoord, vec4(thisThreadDepth, 0.0, 1.0));
        }
    }

    barrier();
    memoryBarrierShared();

    if (all(lessThan(localCoord, ivec2(8)))) {
        thisThreadDepth = vec2(1.0, 0.0);
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k%2, k/2);
            vec2 thisDepth = sharedDepth
                [2 * localCoord.x + offset.x]
                [2 * localCoord.y + offset.y];
            thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
            thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        }
    }

    barrier();
    if (all(lessThan(localCoord, ivec2(8)))) {
        sharedDepth[localCoord.x][localCoord.y] = thisThreadDepth;
        ivec2 writeCoord = 8 * ivec2(gl_WorkGroupID.xy) + localCoord;
        if (all(lessThan(writeCoord, viewSize / 16))) {
            writeCoord.y += viewSize.y * 7 / 8;
            imageStore(colorimg2, writeCoord, vec4(thisThreadDepth, 0.0, 1.0));
        }
    }

    barrier();
    memoryBarrierShared();

    if (all(lessThan(localCoord, ivec2(4)))) {
        thisThreadDepth = vec2(1.0, 0.0);
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k%2, k/2);
            vec2 thisDepth = sharedDepth
                [2 * localCoord.x + offset.x]
                [2 * localCoord.y + offset.y];
            thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
            thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        }
    }

    barrier();
    if (all(lessThan(localCoord, ivec2(4)))) {
        sharedDepth[localCoord.x][localCoord.y] = thisThreadDepth;
        ivec2 writeCoord = 4 * ivec2(gl_WorkGroupID.xy) + localCoord;
        if (all(lessThan(writeCoord, viewSize / 32))) {
            writeCoord.y += viewSize.y * 15 / 16;
            imageStore(colorimg2, writeCoord, vec4(thisThreadDepth, 0.0, 1.0));
        }
    }

    barrier();
    memoryBarrierShared();

    if (all(lessThan(localCoord, ivec2(2)))) {
        thisThreadDepth = vec2(1.0, 0.0);
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k%2, k/2);
            vec2 thisDepth = sharedDepth
                [2 * localCoord.x + offset.x]
                [2 * localCoord.y + offset.y];
            thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
            thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        }
    }

    barrier();
    if (all(lessThan(localCoord, ivec2(2)))) {
        sharedDepth[localCoord.x][localCoord.y] = thisThreadDepth;
        ivec2 writeCoord = 2 * ivec2(gl_WorkGroupID.xy) + localCoord;
        if (all(lessThan(writeCoord, viewSize / 64))) {
            writeCoord.y += viewSize.y * 31 / 32;
            imageStore(colorimg2, writeCoord, vec4(thisThreadDepth, 0.0, 1.0));
        }
    }

    barrier();
    memoryBarrierShared();

    if (localCoord == ivec2(0)) {
        thisThreadDepth = vec2(1.0, 0.0);
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k%2, k/2);
            vec2 thisDepth = sharedDepth
                [2 * localCoord.x + offset.x]
                [2 * localCoord.y + offset.y];
            thisThreadDepth.x = min(thisThreadDepth.x, thisDepth.x);
            thisThreadDepth.y = max(thisThreadDepth.y, thisDepth.y);
        }
    }

    barrier();
    if (localCoord == ivec2(0)) {
        sharedDepth[localCoord.x][localCoord.y] = thisThreadDepth;
        ivec2 writeCoord = ivec2(gl_WorkGroupID.xy);
        if (all(lessThan(writeCoord, viewSize/128))) {
            writeCoord.y += viewSize.y * 63 / 64;
            imageStore(colorimg2, writeCoord, vec4(thisThreadDepth, 0.0, 1.0));
        }
    }
    #endif //FINE_SSRT
}