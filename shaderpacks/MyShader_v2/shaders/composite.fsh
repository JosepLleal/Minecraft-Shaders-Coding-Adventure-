#version 120
#include "distort.glsl"

varying vec2 TexCoords;

uniform vec3 sunPosition;

// The color textures which we wrote to
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

//Unifrom matrices
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

//shadow uniforms
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

/*
const int colortex0Format = RGBA16;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;
const float shadowBias = 0.001f;
float ShadowVisibility1;

#define SHADOW_SAMPLES 2
const int shadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;


const float sunPathRotation = -10.0f;
const float Ambient = 0.1f;

const vec3 TorchColor = vec3(1.0f, 0.35f, 0.28f);
const vec3 skyColor = vec3(0.05f, 0.15f, 0.3f);
vec2 Lightmap;

float AdjustLightmapTorch(in float torch) {
    const float K = 2.5f; //intensity
    const float N = 2.0f; //scatter
    return K * pow(torch, N);
}

float AdjustLightmapSky(in float sky, in float N) {
    float NewSky = pow(sky, N);
    return NewSky;
}

vec2 AdjustLightmap(in vec2 lightmap) {
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(lightmap.x);
    NewLightMap.y = AdjustLightmapSky(lightmap.y, 5.0f);
    return NewLightMap;
    }

vec3 DetermineLightColor(in vec2 lightmap) {
    vec3 skyColor =  skyColor * lightmap.g;
    vec3 torchColor = TorchColor * lightmap.r;

    return skyColor + torchColor;
}

//------SHADOWS---------
float Visibility(in sampler2D ShadowMap, in vec3 uv) {
    return step(uv.z - shadowBias, texture2D(ShadowMap, uv.xy).r);
}

vec3 ColorShadows(in vec3 uv){
    //sample shadow visibility depth textures
    float ShadowVisibility0 = Visibility(shadowtex0, uv);
    //does not contain transparent objects
    ShadowVisibility1 = Visibility(shadowtex1, uv);

    //sample block color
    float Intensity = 4.0f; //shadow color intensity
    vec4 ShadowColor0 = texture2D(shadowcolor0, uv.xy);
    vec3 TransmitedColor = ShadowColor0.rgb;
    
    //interpolate using ShadowVisibility0
    return mix(TransmitedColor * Intensity * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

vec3 GetShadow(in float depth){
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    //convert from clip space to view scpace
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    //convert from view space to world space (actually player space)
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    //convert to shadow space
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    //distort shadows
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    //get [0,1] range
    vec3 uv = ShadowSpace.xyz * 0.5f + 0.5f;

    //Soft shadow Percentage Close Filtering
    vec3 shadowAccum = vec3(0.0f);

    float angle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(angle);
    float sinTheta = sin(angle);
    mat2 rot = mat2(cosTheta, -sinTheta, sinTheta, cosTheta)/shadowMapResolution;

    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 offset = rot * vec2(x, y);
            vec3 currentSampleCoord = vec3(uv.xy + offset, uv.z);
            shadowAccum += ColorShadows(currentSampleCoord);
        }
    }

    return shadowAccum/= pow(shadowSamplesPerSize, 2.0f);
}

void main(){
    // Account for gamma correction
    vec3 Albedo = texture2D(colortex0, TexCoords).rgb;
    Albedo = pow(Albedo, vec3(2.2f));//gamma correct

    //sky correction
    float Depth = texture2D(depthtex0, TexCoords).r;

    if(Depth == 1.0f){
        gl_FragData[0] = vec4(Albedo, 1.0f);
        return;
    }

    // Get the normal
    vec3 Normal = texture2D(colortex1, TexCoords).rgb;
    Normal = Normal * 2.0f - 1.0f;

    //Get Lightmap
    Lightmap = texture2D(colortex2, TexCoords).rg;
    //Adjust lightmap values
    Lightmap = AdjustLightmap(Lightmap);
    //light color to block
    vec3 LightmapColor =  DetermineLightColor(Lightmap);

    // Compute cos theta between the normal and sun directions 
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Do the lighting calculations, Lambert Diffuse
    //vec3 Diffuse = Albedo * (LightmapColor + NdotL + Ambient);
    vec3 Diffuse = Albedo * (LightmapColor + NdotL * GetShadow(Depth) + Ambient);
    //shading using lightmap
    Diffuse *= Lightmap.g + Lightmap.r;

    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}