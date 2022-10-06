#ifndef RAYTRACE
#define RAYTRACE
#include "/lib/vx/voxelMapping.glsl"
#include "/lib/vx/voxelReading.glsl"

mat3 eye = mat3(
    1, 0, 0,
    0, 1, 0,
    0, 0, 1
);
// cuboid intersection algorithm
float aabbIntersect(vxData data, vec3 pos, vec3 dir, inout int n) {
    // offset to work around floating point errors
    vec3 offset = 0.01 * eye[n] * sign(dir[n]);
    // don't need to know global position, only relative to current block
    pos = fract(pos + offset) - offset;
    vec3[2] bounds = vec3[2](data.lower, data.upper);
    float w = 10000;
    for (int i = 0; i < 3; i++) {
        if (dir[i] == 0) continue;
        float relevantBound = bounds[dir[i] < 0 ? 1 : 0][i];
        float w0 = (relevantBound - pos[i]) / dir[i];
        if (w0 < 0.0) relevantBound = bounds[dir[i] < 0 ? 1 : 0][i];
        vec3 newPos = pos + w0 * dir;
        // ray-plane intersection position needs to be closer than the previous best one and further than approximately 0
        bool valid = (w0 > -0.05 / length(dir) && w0 < w);
        for (int j = 1; j < 3; j++) {
            int ij = (i + j) % 3;
            // intersection position also needs to be within other bounds
            if (newPos[ij] < bounds[0][ij] - 0.01 || newPos[ij] > bounds[1][ij] + 0.01) {
                valid = false;
                break;
            }
        }
        // update normal and ray position
        if (valid) {
            w = w0;
            n = i;
        }
    }
    return w;
}
// returns color data of the block at pos, when hit by ray in direction dir
vec4 handledata(vxData data, sampler2D atlas, inout vec3 pos, vec3 dir, int n) {
    if (!data.crossmodel) {
        if (data.cuboid) {
            float w = aabbIntersect(data, pos, dir, n);
            if (w > 9999) return vec4(0);
            pos += w * dir;
        }
        vec2 spritecoord = vec2(n != 0 ? fract(pos.x) : fract(pos.z), n != 1 ? fract(-pos.y) : fract(pos.z)) * 2 - 1;
        vec2 texcoord = data.texcoord + (data.spritesize - 0.5) * spritecoord / atlasSize;
        vec4 color = texture2D(atlas, texcoord);
        if (!data.alphatest) color.a = 1;
        // multiply by vertex color for foliage, water etc
        color.rgb *= data.emissive ? vec3(1) : data.lightcol;
        return color;
    }
    // get around floating point errors using an offset
    vec3 offset = 0.01 * eye[n] * sign(dir[n]);
    vec3 blockInnerPos = fract(pos + offset) - offset;
    // ray-plane intersections
    float w0 = (1 - blockInnerPos.x - blockInnerPos.z) / (dir.x + dir.z);
    float w1 = (blockInnerPos.x - blockInnerPos.z) / (dir.z - dir.x);
    vec3 p0 = blockInnerPos + w0 * dir;
    vec3 p1 = blockInnerPos + w1 * dir;
    bool valid0 = (max(max(abs(p0.x - 0.5), abs(p0.y - 0.5)), abs(p0.z - 0.5)) < 0.48);
    bool valid1 = (max(max(abs(p1.x - 0.5), abs(p1.y - 0.5)), abs(p1.z - 0.5)) < 0.48);
    vec4 color0 = valid0 ? texture2D(atlas, data.texcoord + (data.spritesize - 0.5) * (1 - p0.xy * 2) / atlasSize) : vec4(0);
    vec4 color1 = valid1 ? texture2D(atlas, data.texcoord + (data.spritesize - 0.5) * (1 - p1.xy * 2) / atlasSize) : vec4(0);
    color0.xyz *= data.emissive ? vec3(1) : data.lightcol;
    color1.xyz *= data.emissive ? vec3(1) : data.lightcol;
    if (w0 < w1) {
        pos = color0.a > 0.01 ? p0 : p1;
    } else {
        pos = color1.a > 0.01 ? p1 : p0;
    }
    // the more distant intersection position only contributes by the amount of light coming through the closer one
    return (w0 < w1) ? (vec4(color0.xyz * color0.a, color0.a) + (1 - color0.a) * vec4(color1.xyz * color1.a, color1.a)) : (vec4(color1.xyz * color1.a, color1.a) + (1 - color1.a) * vec4(color0.xyz * color0.a, color0.a));
}
// voxel ray tracer
vec4 raytrace(inout vec3 pos0, vec3 dir, inout vec3 translucentHit, sampler2D atlas, bool translucentData) {
    vec3 progress;
    for (int i = 0; i < 3; i++) {
        //set starting position in each direction
        progress[i] = -(dir[i] < 0 ? fract(pos0[i]) : fract(pos0[i]) - 1) / dir[i];
    }
    int i = 0;
    // get closest starting position
    float w = progress[0];
    for (int i0 = 1; i0 < 3; i0++) {
        if (progress[i0] < w) {
            i = i0;
            w = progress[i];
        }
    }
    // step size in each direction (to keep to the voxel grid)
    vec3 stp = abs(1 / dir);
    float dirlen = length(dir);
    vec3 dirsgn = sign(dir);
    vec3[3] eyeOffsets;
    for (int k = 0; k < 3; k++) {
        eyeOffsets[k] = 0.001 * eye[k] * dirsgn[k];
    }
    vec3 pos = pos0;
    vec4 raycolor = vec4(0);
    vec4 oldRayColor = vec4(0);
    // check if stuff already needs to be done at starting position
    vxData voxeldata = readVxMap(getVxPixelCoords(pos));
    if (voxeldata.trace) {
        raycolor = handledata(voxeldata, atlas, pos, dir, i);
        raycolor.rgb *= raycolor.a;
    }
    if (raycolor.a > 0.01 && raycolor.a < 0.9) translucentHit = pos;
    float invDirLenScaled = 0.001 / dirlen;
    int k = 0; // k is a safety iterator
    int mat = voxeldata.mat; // for inner face culling
    // main loop
    while (w < 1 && k < 2000 && raycolor.a < 0.99) {
        oldRayColor = raycolor;
        pos = pos0 + (w + invDirLenScaled) * dir + eyeOffsets[i];
        // read voxel data at new position and update ray colour accordingly
        if (isInRange(pos)) {
            voxeldata = readVxMap(getVxPixelCoords(pos));
            if (voxeldata.trace) {
                vec4 newcolor = handledata(voxeldata, atlas, pos, dir, i);
                if (voxeldata.mat == mat) newcolor.a = clamp(10.0 * newcolor.a - 9.0, 0.0, 1.0);
                mat = (newcolor.a > 0.1) ? voxeldata.mat : 0;
                raycolor.rgb += (1 - raycolor.a) * newcolor.a * newcolor.rgb;
                raycolor.a += (1 - raycolor.a) * newcolor.a;
                if (oldRayColor.a < 0.01 && raycolor.a > 0.01 && raycolor.a < 0.9) translucentHit = pos;
            }
        }
        // update position
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
vec4 raytrace(inout vec3 pos0, vec3 dir, sampler2D atlas, bool translucentData) {
    vec3 translucentHit = vec3(0);
    return raytrace(pos0, dir, translucentHit, atlas, translucentData);
}
vec4 raytrace(inout vec3 pos0, vec3 dir, sampler2D atlas) {
    return raytrace(pos0, dir, atlas, false);
}
#endif