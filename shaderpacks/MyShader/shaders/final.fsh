#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

void main(){
    //sample the color
    vec3 color = texture2D(colortex0, TexCoords).rgb;
    //convert to grayscale
    color *= vec3(0.0f, 0.0f, 1.0f);
    //output
    gl_FragColor = vec4(color, 1.0f);
}
