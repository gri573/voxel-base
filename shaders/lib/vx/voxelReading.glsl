#ifndef READING
#define READING

#include "/lib/vx/voxelMapping.glsl"

struct vxData {
    vec2 texcoord;
    vec3 lower;
    vec3 upper;
    int mat;
    int lightlevel;
    float spritesize;
    vec3 lightcol;
    bool trace;
    bool full;
    bool cuboid;
    bool alphatest;
    bool emissive;
    bool crossmodel;
};

//read data from the voxel map (excluding flood fill data)

vxData readVxMap(ivec2 coords) {
    ivec4 data0 = ivec4(texelFetch(shadowcolor0, coords, 0) * 65535 + 0.5);
    ivec4 data1 = ivec4(texelFetch(shadowcolor1, coords, 0) * 65535 + 0.5);
    vxData data;
    if (data0.w == 65535) { // if the voxel was not written to, then it has shadowClearColor, which is vec4(1.0)
        data.lightcol = vec3(0); // lightcol is gl_color for anything that isn't a light source
        data.texcoord = vec2(-1);
        data.mat = -1;
        data.lower = vec3(0);
        data.upper = vec3(1);
        data.full = false;
        data.cuboid = false;
        data.alphatest = false;
        data.trace = false;
        data.emissive = false;
        data.crossmodel = false;
        data.spritesize = 0;
        data.lightlevel = 0;
    } else {
        data.lightcol = vec3(data0.x % 256, data0.x / 256, data0.y % 256) / 255;
        data.texcoord = vec2(16 * (data0.y / 256) + data0.z % 16, data0.z / 16) / 4095;
        data.mat = data0.w;
        data.lower = vec3(data1.x % 16, (data1.x / 16) % 16, (data1.x / 256) % 16) / 16.0;
        data.upper = (vec3((data1.x / 4096) % 16, data1.y % 16, (data1.y / 16) % 16) + 1) / 16.0;
        int type = data1.y / 256;
        data.full = ((type / 4) % 2 == 1);
        data.cuboid = ((type / 16) % 2 == 1);
        data.alphatest = (type % 2 == 1);
        data.trace = ((type / 32) % 2 == 0 && data0.w != 65535);
        data.emissive = ((type / 8) % 2 == 1);
        data.crossmodel = ((type / 2) % 2 == 1);
        data.spritesize = pow(2, data1.z % 16);
        data.lightlevel = (data1.z / 16) % 128;
    }
    return data;
}

vxData readVxMap(vec3 vxPos) {
    return readVxMap(getVxPixelCoords(vxPos));
}

#endif