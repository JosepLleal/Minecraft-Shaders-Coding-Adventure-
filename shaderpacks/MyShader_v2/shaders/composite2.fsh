#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float near, far;

uniform vec3 skyColor;  

const float fogDensity = 1.5f;

//from unity Z buffer to linear 0..1 depth (0 at eye, 1 at far plane)
float LinearDepth(float z) {
    return 1.0 / ((1.0 - far / near) * z + far / near);
}

void main() {

    vec3 albedo = texture2D(colortex0, TexCoords).rgb;

    float Depth = texture2D(depthtex0, TexCoords).r;
    Depth = LinearDepth(Depth);
    Depth = Depth*Depth * fogDensity;
    Depth = clamp(Depth, 0, 1);
    
    //dont tint the sun
    if (Depth > 0.99999f){
        gl_FragColor = vec4(albedo, 1.0f);
        return;
    }

    

    vec3 finalColor = mix(albedo, skyColor, Depth);

    //gl_FragColor = vec4(vec3(Depth), 1.0f);
    gl_FragColor = vec4(finalColor, 1.0f);
}