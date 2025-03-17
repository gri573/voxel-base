#version 430 compatibility

uniform sampler2D colortex2;

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);
    ivec2 viewSize = textureSize(colortex2, 0);
    int lodLevel = -1;
    ivec2 lodRelCoord;
    for (int k = 0; k < 10; k++) {
        lodRelCoord = coord - ivec2(0, viewSize.y * ((1<<k)-1)/(1<<k));
        if (lodRelCoord.y < 0) {
            break;
        }
        if (all(lessThan(lodRelCoord, viewSize / (1<<k+1)))) {
            lodLevel = k;
            break;
        }
    }
    vec2 depthRange = vec2(1.0, 0.0);
    if (lodLevel >= 0) {
        for (int k = 0; k < 9; k++) {
            ivec2 offset = ivec2(k%3, k/3) - 1;
            ivec2 newCoord = lodRelCoord + offset;
            if (
                all(greaterThanEqual(newCoord, ivec2(0))) &&
                all(lessThan(newCoord, viewSize / (1<<lodLevel+1)))
            ) {
                vec2 thisDepthRange = texelFetch(colortex2, coord + offset, 0).xy;
                depthRange.x = min(depthRange.x, thisDepthRange.x);
                depthRange.y = max(depthRange.y, thisDepthRange.y);
            }
        }
    }
    /*RENDERTARGETS:2*/
    gl_FragData[0] = vec4(depthRange, 0.0, 1.0);
    //gl_FragData[0] = texelFetch(colortex2, coord, 0);
}