#version 330 compatibility

#include "/lib/common.glsl"

in vec2[3] texCoordV;
in vec2[3] lmCoordV;
in vec3[3] normalV;
in vec4[3] vertexColV;
in vec3[3] posV;
flat in int[3] matV;

out vec2 texCoord;
out vec2 lmCoord;
out vec3 normal;
out vec4 vertexCol;
out vec3 pos;
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
    avgPos += cameraPosition - floor(previousCameraPosition) - 0.05 * normalize(cnormal);//normalize(normalV[0]);
    if (max(abs(avgPos.x), abs(avgPos.z)) < vxRange / 2 && abs(avgPos.y) < VXHEIGHT * VXHEIGHT / 2) {
        vec2 coord = getVxCoords(avgPos);
        for (int i = 0; i < 3; i++) {
            texCoord = texCoordV[i];
            lmCoord = lmCoordV[i];
            normal = normalV[i];
            vertexCol = vertexColV[i];
            pos = avgPos;
            mat = matV[i];
            gl_Position = vec4(coord * 2 - vec2(1) + offsets[i] / shadowMapResolution, 0.5 + (0.5 - mod(avgPos.y, 1.0))*0.2, 1);
            EmitVertex();
        }
        EndPrimitive();
    }
}
