#define MAPPING
//// needs uniform vec3 cameraPosition, previousCameraPosition

// voxel volume diameter
const int vxRange = 2 * (shadowMapResolution / (2 * VXHEIGHT));

// convert 3D position in voxel space to 2D position on the voxel map
vec2 getVxCoords(vec3 voxelPos) {
    voxelPos.y += VXHEIGHT * VXHEIGHT / 2;
    ivec2 coords = ivec2(voxelPos.xz + vxRange / 2);
    coords.x += int(voxelPos.y) % VXHEIGHT * vxRange;
    coords.y += int(voxelPos.y) / VXHEIGHT * vxRange;
    return (coords + vec2(0.5)) / vec2(shadowMapResolution);
}

// inverse function to getVxCoords
vec3 getVxPos(vec2 vxCoords) {
    vxCoords *= shadowMapResolution;
    vec3 pos;
    pos.xz = mod(vxCoords, vec2(vxRange)) - vxRange / 2;
    pos.y = floor(vxCoords.y / vxRange) * VXHEIGHT + floor(vxCoords.x / vxRange) - VXHEIGHT * VXHEIGHT / 2 + 0.5;
    return pos;
}

// get voxel space position from world position
vec3 getVxPos(vec3 worldPos) {
    return worldPos + fract(cameraPosition);
}

// get previous voxel space position from world position
vec3 getPreviousVxPos(vec3 worldPos) {
    return worldPos + (cameraPosition - floor(previousCameraPosition));
}