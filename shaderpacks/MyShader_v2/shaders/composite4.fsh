#version 120
#include "common.glsl"

varying vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

//TONE MAPPING -- UNCHARTED 2 ??

vec3 A = vec3(0.15);
vec3 B = vec3(0.50);
vec3 C = vec3(0.10);
vec3 D = vec3(0.20);
vec3 E = vec3(0.02);
vec3 F = vec3(0.30);
vec3 W = vec3(11.2);

vec3 Uncharted2Tonemap(vec3 x)
{
   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 ps_main( vec3 color)
{
   vec3 texColor = color * vec3(4.0f);  // Hardcoded Exposure Adjustment

   float ExposureBias = 2.0f;
   vec3 curr = Uncharted2Tonemap(vec3(ExposureBias)*texColor);

   vec3 whiteScale = vec3(1.0f)/Uncharted2Tonemap(vec3(W));
   vec3 finalColor = curr*whiteScale;
   vec3 retColor = pow(finalColor,vec3(1/2.2));
   return finalColor;
}

vec3 Reinhard_TM( vec3 color)
{
   vec3 texColor = color * vec3(16.0f);  // Hardcoded Exposure Adjustment
   texColor = texColor/(vec3(1) + texColor);
   vec3 retColor = pow(texColor,vec3(1/2.2));
   return texColor;
}

vec3 baisc_TM(vec3 color )
{
   vec3 texColor = color * vec3(16);  // Hardcoded Exposure Adjustment
   vec3 retColor = pow(texColor,vec3(1/2.2));
   return retColor;
}

void main(){

    vec3 albedo = texture2D(colortex0, TexCoords).rgb;

    //sky correction
    float Depth = texture2D(depthtex0, TexCoords).r;
    if(Depth == 1.0f){
        gl_FragData[0] = vec4(albedo, 1.0f);
        return;
    }

    vec3 albedo2 = albedo;//pow(albedo,vec3(2.2));
    //unhcarted tone map
    vec3 toneMap = ps_main(albedo2);

    //reinhard tone map
    //vec3 toneMap = Reinhard_TM(albedo2);
    //vec3 toneMap = baisc_TM(albedo2);

    /* DRAWBUFFERS:0 */
    gl_FragColor = vec4(toneMap, 1.0f);
    //gl_FragColor = vec4(albedo, 1.0f);
}