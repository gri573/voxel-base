float getCaustics(vec3 worldPos) {
    vec2 causticWind = vec2(frameTimeCounter * 0.04, 0.0);
    float caustic = texture2D(noisetex, worldPos.xz * 0.05 + causticWind).g + texture2D(noisetex, worldPos.xz * 0.1 - causticWind).g;
    return caustic * caustic * 0.3 + 0.1;
}