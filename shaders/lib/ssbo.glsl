#ifndef INCLUDE_LIGHT_BUFFER
#define INCLUDE_LIGHT_BUFFER

#ifndef WRITE_LIGHTS
#define WRITE_LIGHTS readonly
#endif // WRITE_LIGHTS

struct light_t {
    vec3 col;
    float brightness;
    vec3 relPos;
};

light_t unpackLightData(uvec4 packedLight) {
    light_t lightData;
    float instanceCount = float(packedLight.w >> 16);
    lightData.col = vec3(
        packedLight.x & 0xffffu,
        packedLight.x >> 16,
        packedLight.y & 0xffffu
    ) / (32.0 * instanceCount);
    lightData.brightness = float(packedLight.y >> 16) / (15.0 * instanceCount);
    lightData.relPos = vec3(
        packedLight.z & 0xffffu,
        packedLight.z >> 16,
        packedLight.w & 0xffffu
    ) / (32.0 * instanceCount);
    return lightData;
}

// hash function adapted from https://www.shadertoy.com/view/MdcfDj

#define M1 1597334677U     //1719413*929
#define M2 3812015801U     //140473*2467*11
#define M3 2983679513U     //45413*522259

int posHash(ivec3 position) {
    uvec3 q = uvec3(position);
    q *= uvec3(M1, M2, M3);
    uint n = q.x ^ q.y ^ q.z;
    n = n * (n ^ (n >> 15));
    return int(n >> 1);
}

layout(std430, binding=0) WRITE_LIGHTS buffer lightdata {
    uvec4 lightArray[];
};
#endif // INCLUDE_LIGHT_BUFFER