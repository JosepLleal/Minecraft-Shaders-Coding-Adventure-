#version 120

varying vec2 TexCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec2 LightmapCoords;

void main() {
    gl_Position = ftransform();
    
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.xy;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);

    TexCoords = gl_MultiTexCoord0.xy;
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
}