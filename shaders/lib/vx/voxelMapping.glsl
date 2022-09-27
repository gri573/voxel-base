#ifndef MAPPING
#define MAPPING
//// needs uniform vec3 cameraPosition, previousCameraPosition

// voxel volume diameter
const int vxRange = 2 * (shadowMapResolution / (2 * VXHEIGHT));

// convert 3D position in voxel space to 2D position on the voxel map
ivec2 getVxPixelCoords(vec3 voxelPos) {
    voxelPos.y += VXHEIGHT * VXHEIGHT / 2;
    ivec2 coords = ivec2(voxelPos.xz + vxRange / 2);
    coords.x += int(voxelPos.y) % VXHEIGHT * vxRange;
    coords.y += int(voxelPos.y) / VXHEIGHT * vxRange;
    return coords;
}

vec2 getVxCoords(vec3 voxelPos, vec2 size) {
    return (getVxPixelCoords(voxelPos) + vec2(0.5)) / size;
}

vec2 getVxCoords(vec3 voxelPos, float size) {
    return (getVxPixelCoords(voxelPos) + vec2(0.5)) / size;
}

vec2 getVxCoords(vec3 voxelPos) {
    return getVxCoords(voxelPos, shadowMapResolution);
}

// inverse function to getVxCoords
vec3 getVxPos(vec2 vxCoords) {
    vxCoords *= shadowMapResolution;
    vec3 pos;
    pos.xz = mod(vxCoords, vec2(vxRange)) - vxRange / 2;
    pos.y = floor(vxCoords.y / vxRange) * VXHEIGHT + floor(vxCoords.x / vxRange) - VXHEIGHT * VXHEIGHT / 2 + 0.5;
    return pos;
}

vec3 getVxPos(ivec2 vxCoords) {
    //vec2 vxCoords = vxCoords0;
    vec3 pos;
    pos.xz = mod(vxCoords, vec2(vxRange)) - vxRange / 2 + 0.5;
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

// determine if a position is within the voxelisation range
bool isInRange(vec3 pos, float margin) {
    return (max(abs(pos.x), abs(pos.z)) < vxRange / 2 - margin && abs(pos.y) < VXHEIGHT * VXHEIGHT / 2 - margin);
}
bool isInRange(vec3 pos) {
    return isInRange(pos, 0);
}
#endif