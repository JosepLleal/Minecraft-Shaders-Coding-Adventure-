float luminance(vec3 color) {
    return dot(color, vec3(0.2125f, 0.7153f, 0.0721f));
}

float gaussian(int x, float sigma) {
    float sigmaSqu = sigma * sigma;
    return (1 / sqrt(6.28319f * sigmaSqu)) * pow(2.71828f, -(x * x) / (2 * sigmaSqu));
}