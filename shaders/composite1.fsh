#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex15;
ivec2 atlasSize = textureSize(colortex15, 0);

vec2 tex8size = vec2(textureSize(colortex8, 0));

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/raytrace.glsl"

void main() {
    ivec4 dataToWrite = ivec4(texture2D(colortex8, texCoord) * 65535 + 0.5);
    vec2 shadowCoord = texCoord * tex8size / shadowMapResolution;
    if (shadowCoord.x < 1 && shadowCoord.y < 1) {
        vec3 pos0 = getVxPos(shadowCoord);
        vec3 pos = pos0;
        vec3 offset = floor(cameraPosition) - floor(previousCameraPosition);
        int newOcclusionData = 0;
        for (int k = 0; k < 5; k++) {
            vec3 oldPos0 = pos0 + offset;
            int occlusionData = (length(offset) < 0.5) ? dataToWrite.y : int(texture2D(colortex8, getVxCoords(oldPos0) * shadowMapResolution / tex8size).g * 65535 + 0.5);
            occlusionData = (occlusionData >> 3 * k) % 8;
            ivec4 lightData0 = ivec4(texture2D(colortex8, getVxCoords(pos) * shadowMapResolution / tex8size) * 65535 + 0.5);
            ivec4 lightData1 = ivec4(texture2D(colortex9, getVxCoords(pos) * shadowMapResolution / tex8size) * 65535 + 0.5);
            int changed = lightData0.x % 256;
            changed = isInRange(oldPos0) ? changed : 1;
            if (changed > 0) {
                occlusionData = 0;
                vec3[3] lights = vec3[3](
                    vec3(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256),
                    vec3(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256),
                    vec3(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256)
                );
                ivec3 intensities = ivec3(lightData0.w >> 8, lightData1.y >> 8, lightData1.w >> 8);
                for (int i = 0; i < 3; i++) {
                    if (intensities[i] == 0) continue;
                    vec3 lightDir = lights[i] - 127.5 - fract(pos);
                    vec3 endPos = pos;
                    vec3 goalPos = pos + lightDir;
                    raytrace(endPos, lightDir, colortex15);
                    float dist = max(max(abs(endPos.x - goalPos.x), abs(endPos.y - goalPos.y)), abs(endPos.z - goalPos.z));
                    if (dist < 0.505) {
                        occlusionData += 1 << i;
                    }
                }
            }
            newOcclusionData += occlusionData << (3 * k);
            pos *= 0.5;
            offset *= 2;
        }
        dataToWrite.y = newOcclusionData;
    }
    /*RENDERTARGETS:8*/
    gl_FragData[0] = vec4(dataToWrite) / 65535.0;
}