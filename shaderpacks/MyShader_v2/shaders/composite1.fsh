#version 120
#include "common.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;

uniform float viewWidth, viewHeight;
vec2 pixelSize = vec2(1.0/viewWidth, 1.0/viewHeight);

const int KERNEL_SIZE = 16;
const float sigma = 4.0;

void main(){

    vec3 blurColor = vec3(0.0f);
    float totalWeight = 0.0f;

    // Horizontal blur pass
    for (int x = -KERNEL_SIZE/2; x <= KERNEL_SIZE/2; x++){
        float gauss = gaussian(x, sigma);
        totalWeight += gauss;
        blurColor += texture2D(colortex0, TexCoords + vec2(x,0.0)*pixelSize).rgb * gauss;
    }

    // Vertical blur pass
    for (int y = -KERNEL_SIZE/2; y <= KERNEL_SIZE/2; y++){
        float gauss = gaussian(y, sigma);
        totalWeight += gauss;
        blurColor += texture2D(colortex0, TexCoords + vec2(0.0,y)*pixelSize).rgb * gauss;
    }

    blurColor /= totalWeight;

    //bloom
    vec3 albedo = texture2D(colortex0, TexCoords).rgb;
    vec3 finalColor = albedo + blurColor * mix(0.2, 1.5, luminance(blurColor));

    /* DRAWBUFFERS:0 */
    gl_FragColor = vec4(finalColor, 1.0f);
    //gl_FragColor = vec4(albedo, 1.0f);
}