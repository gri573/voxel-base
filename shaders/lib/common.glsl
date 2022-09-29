/*
Shader options and very basic functions, nothing else
*/

const int shadowMapResolution = 1024; //[64 128 256 512 1024 2048 4096]

// voxel volume height
#define VXHEIGHT 8 //[4 5 6 7 8 9 10 11 12 13 14 15 16]

#define OCCLUSION_CASCADE_COUNT 5 //[1 2 3 4 5]

#define BLOCKLIGHT_STRENGTH 1.0 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.5 1.7 2.0]

#define BLOCKLIGHT_STEEPNESS 2.0 //[1.0 1.3 1.5 1.7 2.0]

#define OCCLUSION_FILTER 1 //[0 1 2]

#define SUN_ANGLE 0.5 //[-0.5 0 0.5]

#define SUN_CHECK_SPREAD 3 //[2 3]

#define SUN_CHECK_INTERVAL 20 //[5 7 10 15 20 30]

const float shadowDistance = 30; //[20 30 40 50 60 70 80 90 100 110 120]
const float shadowDistanceRenderMul = 1.0;

/*
const int shadowcolor0Format = RGBA16;
const int shadowcolor1Format = RGBA16;
const int colortex8Format = RGBA16;
const int colortex9Format = RGBA16;
const int colortex10Format = RGBA16;
*/

const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;