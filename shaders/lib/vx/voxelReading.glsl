#define READING

struct vxData {
    vec2 texcoord;
    vec3 lower;
    vec3 upper;
    int mat;
    float spritesize;
    vec3 lightcol;
    bool trace;
    bool full;
    bool cuboid;
    bool alphatest;
    bool emissive;
    bool crossmodel;
};

vxData readVxMap(vec2 coords){
    ivec4 data0 = ivec4(texture2D(shadowcolor0, coords) * 65535 + 0.5);
    ivec4 data1 = ivec4(texture2D(shadowcolor1, coords) * 65535 + 0.5);
    vxData data;
    data.lightcol = vec3(data0.x % 256, data0.x / 256, data0.y % 256) / 255;
    data.texcoord = vec2(16 * (data0.y / 256) + data0.z % 16, data0.z / 16) / 4095;
    data.mat = data0.w;
    data.lower = vec3(data1.x % 16, (data1.x / 16) % 16, (data1.x / 256) % 16) / 16;
    data.upper = vec3((data1.x / 4096) % 16, data1.y % 16, (data1.y / 16) % 16) / 16;
    int type = data1.y / 256;
    data.full = ((type / 4) % 2 == 1);
    data.cuboid = ((type / 16) % 2 == 1);
    data.alphatest = (type % 2 == 1);
    data.trace = ((type / 32) % 2 == 0 && data0.w != 65535);
    data.emissive = ((type / 8) % 2 == 1);
    data.crossmodel = ((type / 2) % 2 == 1);
    data.spritesize = pow(2, data1.z % 16);
    return data;
};