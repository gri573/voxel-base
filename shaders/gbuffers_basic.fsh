#version 330 compatibility

#include "/lib/common.glsl"

in vec2 lmCoord;
in vec2 texCoord;
in vec3 worldPos;
in vec4 vertexCol;
in vec3 normal;

uniform int worldTime;
uniform vec3 fogColor;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D tex;
uniform ivec2 atlasSize;

#include "/lib/vx/getLighting.glsl"

void main() {
    vec2 tex8size = vec2(textureSize(colortex8, 0));
    vec4 color = texture2D(tex, texCoord) * vertexCol;
    //vec3 vxPosOld = getPreviousVxPos(worldPos + 0.1 * normal);
    vec3 vxPos = getVxPos(worldPos + 0.01 * normal);
    vec3 vxPosOld = vxPos + floor(cameraPosition) - floor(previousCameraPosition);
    /*if (isInRange(vxPosOld) && isInRange(vxPos)) {
        vec2 vxCoordsFF = getVxCoords(vxPosOld) * shadowMapResolution / tex8size;
        ivec4 lightData = ivec4(texture2D(colortex8, vxCoordsFF) * 65535 + 0.5);
        vec3 lightPos = vec3(lightData.z % 256, lightData.z >> 8, lightData.w % 256) - 128;
        if (lightData.w >> 8 != 0) {
            int visible = getOcclusion(vxPosOld).x;
            vec2 lightCoords = getVxCoords(vxPos + lightPos);
            vxData lightBlockData = readVxMap(lightCoords);
            color.rgb *= lightBlockData.lightcol * ((lightData.w >> 8) / 16.0 + 0.1) * vec3(visible, 1, 1);//lightPos * 0.1 + 0.5;
        }
    }*/
    float dayTime = (worldTime % 24000) * 0.0002618;
    const vec2 sunRotationData = vec2(cos(SUN_ANGLE), sin(SUN_ANGLE));
    vec3 sunVec = vec3(sin(dayTime), sunRotationData * cos(dayTime));
    sunVec *= sign(sunVec.y);
    float ndotl = dot(normal, sunVec);
    vec3 lightCol = getBlockLight(vxPos, normal) + 0.6 * lmCoord.y * fogColor + 0.2 + (ndotl > 0 ? 0.7 * ndotl * vec3(1.0, 0.8, 0.7) * getSunLight(vxPosOld) : vec3(0.0));
    color.rgb *= lightCol;
    /*RENDERTARGETS:0*/
    gl_FragData[0] = color;
}