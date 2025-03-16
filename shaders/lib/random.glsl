#ifndef INCLUDE_RANDOM
#define INCLUDE_RANDOM

uint murmur_seed = 0u;

void generateSeed(ivec2 coord, int frameCounter) {
    murmur_seed = uint(frameCounter * int(coord.x + 1657 * coord.y));
}

uint nextUint() {
    uint seed = (murmur_seed += 0x9e3779b9u);
    seed = (seed ^ (seed >> 16)) * 0x85ebca6bu;
    seed = (seed ^ (seed >> 13)) * 0xc2b2ae35u;
    return seed ^ (seed >> 16);
}

float nextFloat() {
    return float(nextUint()) / float(0xffffffffu);
}

vec2 randomGaussian() {
    float a = 1.0, b = 1.0, s = 2.0;
    while (s > 1.0) {
        a = nextFloat();
        b = nextFloat();
        s = a*a+b*b;
    }
    return vec2(a, b) * sqrt(-2.0 * log(s) / s);
}

vec3 randomSphereSample() {
    float z = 2.0 * nextFloat() - 1.0;
    float a = 2 * 3.14159 * nextFloat();
    return vec3(vec2(cos(a), sin(a)) * sqrt(1.0 - z*z), z);
}

vec3 randomCosineWeightedHemisphereSample(vec3 normal) {
    return normalize(randomSphereSample() + normal);
}

#endif //INCLUDE_RANDOM
