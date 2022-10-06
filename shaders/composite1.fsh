// calculate visibility of light sources

#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texCoord;
in vec3 sunDir;

uniform int frameCounter;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D noisetex;
#ifdef SUN_SHADOWS
uniform sampler2D colortex10;
#endif
uniform sampler2D colortex15; // texture atlas
ivec2 atlasSize = textureSize(colortex15, 0);

vec2 tex8size = vec2(textureSize(colortex8, 0));

ivec3[7] offsets = ivec3[7](ivec3(0), ivec3(-1, 0, 0), ivec3(0, -1, 0), ivec3(0, 0, -1), ivec3(1, 0, 0), ivec3(0, 1, 0), ivec3(0, 0, 1));
vec3[6] randomOffsets = vec3[6](vec3(0.64, -0.05, 0.46), vec3(0.39, -0.93, 0.92), vec3(-0.52, -0.42, -0.06), vec3(0.28, 0.11, 0.51), vec3(0.87, 0.6, 0.3), vec3(-0.15, 0.04, -0.97));

#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"
#include "/lib/vx/raytrace.glsl"
#include "/lib/atmospherics/caustics.glsl"

void main() {
    ivec4 dataToWrite0;
    ivec4 dataToWrite1;
    ivec2 pixelCoord = ivec2(texCoord * tex8size);
    if (max(pixelCoord.x, pixelCoord.y) < shadowMapResolution) {
        dataToWrite0 = ivec4(texelFetch(colortex8, pixelCoord, 0) * 65535 + 0.5);
        #ifdef SUN_SHADOWS
        dataToWrite1 = ivec4(texelFetch(colortex10, pixelCoord, 0) * 65535 + 0.5);
        #endif
        vec3 pos0 = getVxPos(pixelCoord);
        vec3 pos = pos0;
        vec3 offset0 = floor(cameraPosition) - floor(previousCameraPosition);
        vec3 offset = offset0;
        vec3 oldPos = pos + offset;
        // only do sunlight every SUN_CHECK_INTERVAL frames // outdated comment
        //#undef SUN_SHADOWS
        #ifdef SUN_SHADOWS
        vec3 sunMoonDir = sunDir * (sunDir.y > 0.0 ? 1.0 : -1.0);
        vec3 topDownPos = 1.5 * vec3((pixelCoord.x + 0.5) / shadowMapResolution - 0.5, (pixelCoord.y + 0.5) / shadowMapResolution - 0.5, 0) * vxRange;
        vec4 sunPos0 = getSunRayStartPos(topDownPos, sunMoonDir);
        vec3 sunPos = sunPos0.xyz;
        vec3 transPos = vec3(-10000); // translucent Position
        vec4 sunRayColor = sunPos0.w < 0 ? raytrace(sunPos, sunMoonDir * sunPos0.w, transPos, colortex15, true) : vec4(0, 0, 0, 1);
        int transMat = transPos.y > -9999 ? readVxMap(transPos).mat : 0;
        // 31000 is water
        sunRayColor.rgb = (sunRayColor.rgb * sunRayColor.a + 1.0 - sunRayColor.a) * (transMat == 31000 ? getCaustics(transPos + floor(cameraPosition)) * 3.3 : 1);
        sunRayColor.rgb = clamp(sunRayColor.rgb, vec3(0), vec3(1));
        dataToWrite1.r = int(sunRayColor.r * 15.5) + (int(sunRayColor.g * 15.5) << 4) + (int(sunRayColor.b * 15.5) << 8);
        dataToWrite1.g = int((0.5 + dot(sunPos, sunDir) / (1.5  * vxRange)) * 65535 + 0.5);
        dataToWrite1.b = int((0.5 + dot(transPos.y > -9999 ? transPos : sunPos, sunDir) / (1.5  * vxRange)) * 65535 + 0.5);
        #endif
        int newOcclusionData = 0;
        // do occlusion checks at different zoom levels
        for (int k = 0; k < OCCLUSION_CASCADE_COUNT; k++) {
            // oldPos0 is the position this iteration had on the voxel map in the previous frame
            vec3 oldPos0 = pos0 + offset;
            int occlusionData = (length(offset) < 0.5) ? dataToWrite0.y : int(texelFetch(colortex8, getVxPixelCoords(oldPos0), 0).g * 65535 + 0.5);
            occlusionData = (occlusionData >> 3 * k) % 8;
            bool doBlockLight = (int(pos.y) % BLOCKLIGHT_CHECK_INTERVAL == frameCounter % BLOCKLIGHT_CHECK_INTERVAL);
            if (doBlockLight || !isInRange(oldPos0)) {
                ivec4 lightData0 = ivec4(texelFetch(colortex8, getVxPixelCoords(pos), 0) * 65535 + 0.5);
                ivec4 lightData1 = ivec4(texelFetch(colortex9, getVxPixelCoords(pos), 0) * 65535 + 0.5);
                int changed = isInRange(oldPos0) ? lightData0.x % 256 : 1;
                if (changed > 0) {
                    occlusionData = 0;
                    vec3[3] lights = vec3[3](
                        vec3(lightData0.z % 256, lightData0.z >> 8, lightData0.w % 256),
                        vec3(lightData1.x % 256, lightData1.x >> 8, lightData1.y % 256),
                        vec3(lightData1.z % 256, lightData1.z >> 8, lightData1.w % 256)
                    );
                    ivec3 intensities = ivec3(lightData0.w >> 8, lightData1.y >> 8, lightData1.w >> 8);
                    // check for each light source if it is occluded
                    for (int i = 0; i < 3; i++) {
                        if (intensities[i] == 0) continue;
                        vec3 lightDir = lights[i] - 127.5 - fract(pos);
                        vec3 endPos = pos;
                        vec3 goalPos = pos + lightDir;
                        float rayAlpha = raytrace(endPos, lightDir + 0.01 * randomOffsets[frameCounter % 6], colortex15, true).w;
                        float dist = max(max(abs(endPos.x - goalPos.x), abs(endPos.y - goalPos.y)), abs(endPos.z - goalPos.z));
                        if (dist < 0.505 && rayAlpha < 0.5) {
                            occlusionData += 1 << i;
                        }
                    }
                    if (k == 0 && changed == 1) {
                        dataToWrite0.x = (dataToWrite0.x >> 8) << 8;
                    }
                }
            }
            newOcclusionData += occlusionData << (3 * k);
            // zoom in
            pos *= 0.5;
            offset *= 2;
        }
        //write data
        dataToWrite0.y = newOcclusionData;
    }
    /*RENDERTARGETS:8*/
    gl_FragData[0] = vec4(dataToWrite0) / 65535.0;
    #ifdef SUN_SHADOWS
    /*RENDERTARGETS:8,10*/
    gl_FragData[1] = vec4(dataToWrite1) / 65535.0;
    #endif
}