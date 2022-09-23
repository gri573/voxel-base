#ifndef MAPPING
#include "/lib/vx/voxelMapping.glsl"
#endif
#ifndef READING
#include "/lib/vx/voxelReading.glsl"
#endif

mat3 eye = mat3(
    1, 0, 0,
    0, 1, 0,
    0, 0, 1
);

float aabbIntersect(vxData data, vec3 pos, vec3 dir) {
    pos = fract(pos + 0.01 * normalize(dir)) - 0.01 * normalize(dir);
    vec3[2] bounds = vec3[2](data.lower, data.upper);
    float w = 10000;
    for (int i = 0; i < 3; i++) {
        if (dir[i] == 0) continue;
        float relevantBound = bounds[dir[i] < 0 ? 1 : 0][i];
        float w0 = (relevantBound - pos[i]) / dir[i];
        vec3 newPos = pos + w0 * dir;
        bool valid = (w0 > -0.01 / length(dir) && w0 < w);
        for (int j = 1; j < 3 && valid; j++) {
            int ij = (i + j) % 3;
            if (newPos[ij] < bounds[0][ij] - 0.01 || newPos[ij] > bounds[1][ij] + 0.01) valid = false;
        }
        if (valid) w = w0;
    }
    return w;
}

vec4 handledata(vxData data, sampler2D atlas, vec3 pos, vec3 dir, int n) {
    if (!data.crossmodel) {
        if (data.cuboid) {
            float w = aabbIntersect(data, pos, dir);
            if (w > 9999) return vec4(0);
            pos += w * dir;
        }
        vec2 spritecoord = vec2(n != 0 ? fract(pos.x) : fract(pos.z), n != 1 ? fract(-pos.y) : fract(pos.z)) * 2 - 1;
        vec2 texcoord = data.texcoord + data.spritesize * spritecoord / atlasSize;
        vec4 color = data.alphatest ? texture2D(atlas, texcoord) : vec4(0, 0, 0, 1);
        color.rgb *= data.emissive ? vec3(1) : data.lightcol;
        return color;
    }
    pos = fract(pos + 0.01 * dir) - 0.01 * dir;
    float w0 = (1 - pos.x - pos.z) / (dir.x + dir.z);
    float w1 = (pos.x - pos.z) / (dir.z - dir.x);
    vec3 p0 = pos + w0 * dir;
    vec3 p1 = pos + w1 * dir;
    bool valid0 = (max(max(abs(p0.x - 0.5), abs(p0.y - 0.5)), abs(p0.z - 0.5)) < 0.48);
    bool valid1 = (max(max(abs(p1.x - 0.5), abs(p1.y - 0.5)), abs(p1.z - 0.5)) < 0.48);
    vec4 color0 = valid0 ? texture2D(atlas, data.texcoord + data.spritesize * (p0.xy * 2 - 1) / atlasSize) : vec4(0);
    vec4 color1 = valid1 ? texture2D(atlas, data.texcoord + data.spritesize * (p1.xy * 2 - 1) / atlasSize) : vec4(0);
    return (w0 < w1) ? (vec4(color0.xyz * color0.a, color0.a) + (1 - color0.a) * vec4(color1.xyz * color1.a, color1.a)) : (vec4(color1.xyz * color1.a, color1.a) + (1 - color1.a) * vec4(color0.xyz * color0.a, color0.a));
}

vec4 raytrace(inout vec3 pos0, vec3 dir, sampler2D atlas, bool translucentData) {
    vec3 progress;
    for (int i = 0; i < 3; i++) {
        progress[i] = -(dir[i] < 0 ? fract(pos0[i]) : fract(pos0[i]) - 1) / dir[i];
    }
    int i = 0;
    float w = progress[0];
    for (int i0 = 1; i0 < 3; i0++) {
        if (progress[i0] < w) {
            i = i0;
            w = progress[i];
        }
    }
    vec3 stp = abs(1/dir);
    vec3 pos = pos0;
    vec4 raycolor = vec4(0);
    vec4 oldRayColor = vec4(0);
    vxData voxeldata = readVxMap(getVxCoords(pos));
    if (voxeldata.trace) {
        raycolor = handledata(voxeldata, atlas, pos, dir, i);
        raycolor.rgb *= raycolor.a;
    }
    int k = 0;
    while (w < 1 && k < 2000 && raycolor.a < 0.95) {
        oldRayColor = raycolor;
        pos = pos0 + w * dir + 0.1 * eye[i] * sign(dir[i]);
        voxeldata = readVxMap(getVxCoords(pos));
        if (voxeldata.trace) {
            vec4 newcolor = handledata(voxeldata, atlas, pos0 + w * dir, dir, i);
            raycolor.rgb += (1 - raycolor.a) * newcolor.a * newcolor.rgb;
            raycolor.a += (1 - raycolor.a) * newcolor.a;
        }
        k += 1;
        progress[i] += stp[i];
        w = progress[0];
        i = 0;
        for (int i0 = 1; i0 < 3; i0++) {
            if (progress[i0] < w) {
                i = i0;
                w = progress[i];
            }
        }
    }
    pos0 = pos;
    raycolor = (k == 2000 ? vec4(1, 0, 0, 1) : raycolor);
    return translucentData ? oldRayColor : raycolor;
}
vec4 raytrace(inout vec3 pos0, vec3 dir, sampler2D atlas) {
    return raytrace(pos0, dir, atlas, false);
}
