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

vec4 handledata(vxData data, sampler2D atlas, vec3 pos, vec3 dir, int n) {
    vec2 spritecoord = vec2(n != 0 ? fract(pos.x) : fract(pos.z), n != 1 ? fract(-pos.y) : fract(pos.z)) * 2 - 1;
    vec2 texcoord = data.texcoord + data.spritesize * spritecoord / atlasSize;
    vec4 color = texture2D(atlas, texcoord); 
    color.rgb *= data.emissive ? vec3(1) : data.lightcol;
    return color;
}

vec4 raytrace(inout vec3 pos0, vec3 dir, sampler2D atlas) {
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
    vxData voxeldata = readVxMap(getVxCoords(pos));
    if (voxeldata.trace) {
        vec4 newcolor = handledata(voxeldata, atlas, pos, dir, i);
        raycolor.rgb = mix(newcolor.rgb * newcolor.a, raycolor.rgb, raycolor.a);
        raycolor.a += (1 - raycolor.a) * newcolor.a;
    }
    int k = 0;
    while (w < 1 && k < 2000 && raycolor.a < 0.95) {
        pos = pos0 + w * dir + 0.1 * eye[i] * sign(dir[i]);
        voxeldata = readVxMap(getVxCoords(pos));
        if (voxeldata.trace) {
            vec4 newcolor = handledata(voxeldata, atlas, pos, dir, i);
            raycolor.rgb = mix(newcolor.rgb * newcolor.a, raycolor.rgb, raycolor.a);
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
    raycolor = (k == 2000 ? vec4(1, 0, 0, 1) : raycolor);
    return raycolor;
}
