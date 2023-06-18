#version 120

varying vec2 TexCoords;


uniform vec3 sunPosition;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const float sunPathRotation = -40.0f;
const float Ambient = 0.33f;

float AdjustLightmapTorch(in float torch) {
    const float K = 3.0f;
    const float N = 4.0f;
    return K * pow(torch, N);
}

float AdjustLightmapSky(in float sky, in float N) {
    float NewSky = pow(sky, N);
    return NewSky;
}

vec2 AdjustLightmap(in vec2 Lightmap) {
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y, 3.0f);
    return NewLightMap;
}

void main(){
    // Account for gamma correction
    vec3 Albedo = texture2D(colortex0, TexCoords).rgb;
    // Get the normal
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2.0f - 1.0f);

    //Get Lightmap
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    Lightmap = AdjustLightmap(Lightmap);

    // Compute cos theta between the normal and sun directions
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Do the lighting calculations
    vec3 Diffuse = Albedo * (NdotL + Ambient);

    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    //gl_FragData[0] = vec4(Diffuse, 1.0f);
    gl_FragData[0] = vec4(Lightmap, 0.0f, 1.0f);
}