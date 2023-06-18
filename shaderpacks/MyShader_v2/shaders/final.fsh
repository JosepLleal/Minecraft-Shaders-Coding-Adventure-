#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

const float gamma = 1.2f;

void main() {

    // Sample and apply gamma correction
    vec3 Color = pow(texture2D(colortex0, TexCoords).rgb, vec3(1.0f / gamma));
    gl_FragColor = vec4(Color, 1.0f);
}