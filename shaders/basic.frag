#version 130

// Else some GPUs will complain
precision highp float;

uniform vec4 color;

in vec3 brightnessMap;
out vec4 outColor;


void main() {
    outColor = vec4((color.xyz*brightnessMap), color.w);
}