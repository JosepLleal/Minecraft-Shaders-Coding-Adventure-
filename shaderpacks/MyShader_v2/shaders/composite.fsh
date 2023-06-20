#version 120

varying vec2 TexCoords;
uniform vec3 sunPosition;
//uniform vec3 skyColor;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const float sunPathRotation = -20.0f;
const float Ambient = 0.1f;

const vec3 TorchColor = vec3(1.0f, 0.25f, 0.08f);
const vec3 skyColor = vec3(0.05f, 0.15f, 0.3f);

float AdjustLightmapTorch(in float torch) {
    const float K = 3.0f; //intensity
    const float N = 5.0f; //scatter
    return K * pow(torch, N);
}

float AdjustLightmapSky(in float sky, in float N) {
    float NewSky = pow(sky, N);
    return NewSky;
}

vec2 AdjustLightmap(in vec2 lightmap) {
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(lightmap.x);
    NewLightMap.y = AdjustLightmapSky(lightmap.y, 4.0f);
    return NewLightMap;
    }

vec3 DetermineLightColor(in vec2 lightmap) {
    vec3 skyColor =  skyColor * lightmap.g;
    vec3 torchColor = TorchColor * lightmap.r;

    return skyColor + torchColor;
}


void main(){
    // Account for gamma correction
    vec3 Albedo = texture2D(colortex0, TexCoords).rgb;
    Albedo = pow(Albedo, vec3(2.2f));//gamma correct

    // Get the normal
    vec3 Normal = texture2D(colortex1, TexCoords).rgb;
    Normal = Normal * 2.0f - 1.0f;

    //Get Lightmap
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    //Adjust lightmap values
    Lightmap = AdjustLightmap(Lightmap);
    //light color to block
    vec3 LightmapColor =  DetermineLightColor(Lightmap);

    // Compute cos theta between the normal and sun directions 
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Do the lighting calculations, Lambert Diffuse
    vec3 Diffuse = Albedo * (LightmapColor + NdotL + Ambient);
    
    //shading using lightmap
    Diffuse*=clamp(Lightmap.g + Lightmap.r, 0.0f, 1.0f);

    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}