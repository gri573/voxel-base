#version 430 compatibility

layout(r32ui) uniform uimage3D voxelImg;

#include "/lib/voxel_settings.glsl

#define WRITE_LIGHTS
#include "/lib/ssbo.glsl"

uniform int renderStage;
uniform vec2 atlasSize;
uniform vec3 cameraPositionFract;
uniform ivec3 cameraPositionInt;
uniform mat4 shadowModelViewInverse;
uniform sampler2D tex;

in vec2 mc_midTexCoord;
in vec4 at_midBlock;
in vec4 mc_Entity;

float infnorm(vec3 x) {
    return max(max(abs(x.x), abs(x.y)), abs(x.z));
}

void main() {
    if (any(equal(ivec4(renderStage), ivec4(
            MC_RENDER_STAGE_TERRAIN_SOLID,
            MC_RENDER_STAGE_TERRAIN_CUTOUT,
            MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED,
            MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
    )))) {
        vec4 position = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        vec3 blockRelPos = -1.0/64.0 * at_midBlock.xyz;
        position.xyz /= position.w;
        position.xyz += cameraPositionFract - blockRelPos;
        ivec3 correspondingBlock = ivec3(position.xyz + VOXEL_DIST + 1000) - 1000;
        if (
            all(greaterThanEqual(correspondingBlock, ivec3(0))) &&
            all(lessThan(correspondingBlock, ivec3(2 * VOXEL_DIST)))
        ) {
            vec2 texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            vec3 normal = mat3(shadowModelViewInverse) * gl_NormalMatrix * gl_Normal;
            ivec3 blockMod2 = correspondingBlock%2;
            int voxelMapWriteOffset = 4 * (blockMod2.x + 2 * blockMod2.y + 4 * blockMod2.z);
            ivec3 writeCoords = correspondingBlock/2;
            if (at_midBlock.w > 0.5) {
                int lightStoragePosition = posHash(correspondingBlock) % 1000000;
                vec3 lightCol = texture(tex, mc_midTexCoord).rgb;
                vec3 relPos = 1.5 + 0.5 / 32.0 + blockRelPos;
                uvec4 lightToWrite = uvec4(
                    uint(32.0 * lightCol.x) | uint(32.0 * lightCol.y) << 16u,
                    uint(32.0 * lightCol.z) | uint(at_midBlock.w + 0.5) << 16u,
                    uint(32.0 * relPos.x)   | uint(32.0 * relPos.y) << 16u,
                    uint(32.0 * relPos.z)   | uint(1) << 16u
                );
                for (int i = 0; i < 4; i++) {
                    atomicAdd(lightArray[lightStoragePosition][i], lightToWrite[i]);
                }
                imageAtomicOr(voxelImg, writeCoords, 1u << uint(voxelMapWriteOffset + 3));
            } else if (
                renderStage == MC_RENDER_STAGE_TERRAIN_SOLID &&
                infnorm(normal) > 0.99 &&
                dot(normal, blockRelPos) > 0.45 &&
                length(abs(blockRelPos) - infnorm(blockRelPos)) < 0.05 &&
                all(lessThan(
                    abs(abs(texCoord - mc_midTexCoord) * textureSize(tex, 0) - 0.5 * TEXTURE_RES),
                    vec2(0.5)
                ))
            ) {
                if (any(lessThan(normal, vec3(-0.5)))) {
                    correspondingBlock += ivec3(1.5 * normal);
                    normal = -normal;
                    blockMod2 = correspondingBlock%2;
                    voxelMapWriteOffset = 4 * (blockMod2.x + 2 * blockMod2.y + 4 * blockMod2.z);
                    writeCoords = correspondingBlock/2;

                }
                int axis = int(dot(normal, vec3(0.5, 1.5, 2.5)));
                imageAtomicOr(voxelImg, writeCoords, 1u << uint(voxelMapWriteOffset + axis));
            }
        }
    }
    gl_Position = vec4(-1);
}