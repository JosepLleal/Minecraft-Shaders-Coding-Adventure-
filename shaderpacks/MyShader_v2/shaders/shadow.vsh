#version 120
#include "distort.glsl"

void main(){
    gl_Position = ftransform();
}