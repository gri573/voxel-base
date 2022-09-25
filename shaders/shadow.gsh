#version 330 compatibility

#include "/lib/common.glsl"

in vec2[3] texCoordV;
in vec2[3] lmCoordV;
in vec4[3] vertexColV;
in vec3[3] posV;
flat in int[3] spriteSizeV;
flat in int[3] matV;

out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal;
out vec4 vertexCol;
out vec3 pos;
flat out int spriteSize;
flat out int mat;
const int maxVerticesOut = 3;

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

#include "/lib/vx/voxelMapping.glsl"

const vec2[3] offsets = vec2[3](vec2(-1.0, -1.0), vec2(0.0, 1.0), vec2(1.0, -1.0));

void main() {
    vec3 avgPos = (posV[0] + posV[1] + posV[2]) / 3.0;
    vec3 cnormal = cross(posV[0] - posV[1], posV[0] - posV[2]);
    float area = length(cnormal);
    cnormal = normalize(cnormal);
    avgPos += fract(cameraPosition);
    bool tracemat = true;
    float zpos = 0.5 - sqrt(area) - 0.02 * fract(avgPos.y + 0.01) - 0.01 * fract(avgPos.x + 0.01)- 0.15 * fract(avgPos.z + 0.01) - 0.2 * cnormal.y;
    switch (matV[0]) {
        case 31000:
        case 10068:
            if (area < 0.8) tracemat = false;
            break;
        case 10072:
        case 10076:
            vec3 tempPos = fract(avgPos - 0.5);
            if (max(tempPos.x, max(tempPos.y, tempPos.z)) > 0.49) tracemat = false;
            break;
        case 10496:
            avgPos += vec3(0.0, 0.1, 0.0);// + 0.5 * cnormal;
            break;
        case 50016:
            tracemat = false;
            break;
        default:
            avgPos -= 0.05 * cnormal;
            break;
    }
    if (max(abs(avgPos.x), abs(avgPos.z)) < vxRange / 2 && abs(avgPos.y) < VXHEIGHT * VXHEIGHT / 2 && tracemat) {
        vec2 coord = getVxCoords(avgPos);
        for (int i = 0; i < 3; i++) {
            texCoord = texCoordV[i];
            lmCoord = lmCoordV[i];
            normal = cnormal;
            vertexCol = vertexColV[i];
            vertexCol.a = area;
            pos = avgPos;
            mat = matV[i];
            spriteSize = spriteSizeV[i];
            gl_Position = vec4(coord * 2 - vec2(1) + offsets[i] / shadowMapResolution, zpos, 1);
            EmitVertex();
        }
        EndPrimitive();
    }
}
