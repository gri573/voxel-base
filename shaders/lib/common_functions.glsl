#ifndef INCLUDE_COMMONFUNCS
#define INCLUDE_COMMONFUNCS

float infnorm(vec2 x) {
    return max(abs(x.x), abs(x.y));
}
float infnorm(vec3 x) {
    return max(max(abs(x.x), abs(x.y)), abs(x.z));
}
float infnorm(vec4 x) {
    return max(max(abs(x.x), abs(x.y)), max(abs(x.z), abs(x.w)));
}

#endif //INCLUDE_COMMONFUNCS