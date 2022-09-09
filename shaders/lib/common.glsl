/*
Shader options and very basic functions, nothing else
*/

const int shadowMapResolution = 1024; //[64 128 256 512 1024 2048 4096]

// voxel volume height
#define VXHEIGHT 8 //[4 5 6 7 8 9 10 11 12 13 14 15 16]

const float shadowDistance = 20;// float(shadowMapResolution / VXHEIGHT);
const float shadowDistanceRenderMul = 1.0;