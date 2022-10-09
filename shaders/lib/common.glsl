/*
Shader options and very basic functions, nothing else
*/
    const int shadowMapResolution = 1024; //[512 1024 2048 4096]

    #define VXHEIGHT 8 //[4 6 8 12 16]

    #define OCCLUSION_CASCADE_COUNT 5 //[1 2 3 4 5]

    #define BLOCKLIGHT_STRENGTH 1.0 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.5 1.7 2.0]
    #define BLOCKLIGHT_STEEPNESS 2.0 //[1.0 1.3 1.5 1.7 2.0]

    #define OCCLUSION_FILTER 1 //[0 1 2]
    #define SMOOTH_LIGHTING 1 //[0 1 2]

    #define SUN_SHADOWS
    #define SUN_ANGLE 0.5 //[-0.5 0 0.5]
    #define SUN_CHECK_SPREAD 3 //[2 3]
    #define BLOCKLIGHT_CHECK_INTERVAL 17 //[4 5 7 10 15 17 20 30]

    #if (shadowMapResolution == 512)
        #if (VXHEIGHT == 4)
            const float shadowDistance = 64;
        #elif (VXHEIGHT == 6)
            const float shadowDistance = 42;
        #elif (VXHEIGHT == 8)
            const float shadowDistance = 32;
        #elif (VXHEIGHT == 12)
            const float shadowDistance = 21;
        #elif (VXHEIGHT == 16)
            const float shadowDistance = 16;
        #endif
    #elif (shadowMapResolution == 1024)
        #if (VXHEIGHT == 4)
            const float shadowDistance = 128;
        #elif (VXHEIGHT == 6)
            const float shadowDistance = 85;
        #elif (VXHEIGHT == 8)
            const float shadowDistance = 64;
        #elif (VXHEIGHT == 12)
            const float shadowDistance = 42;
        #elif (VXHEIGHT == 16)
            const float shadowDistance = 32;
        #endif
    #elif (shadowMapResolution == 2048)
        #if (VXHEIGHT == 4)
            const float shadowDistance = 256;
        #elif (VXHEIGHT == 6)
            const float shadowDistance = 170;
        #elif (VXHEIGHT == 8)
            const float shadowDistance = 128;
        #elif (VXHEIGHT == 12)
            const float shadowDistance = 85;
        #elif (VXHEIGHT == 16)
            const float shadowDistance = 64;
        #endif
    #elif (shadowMapResolution == 4096)
        #if (VXHEIGHT == 4)
            const float shadowDistance = 512;
        #elif (VXHEIGHT == 6)
            const float shadowDistance = 341;
        #elif (VXHEIGHT == 8)
            const float shadowDistance = 256;
        #elif (VXHEIGHT == 12)
            const float shadowDistance = 170;
        #elif (VXHEIGHT == 16)
            const float shadowDistance = 128;
        #endif
    #endif

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

//infinite... almost
#define INF 100000.0
