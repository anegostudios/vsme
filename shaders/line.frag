#version 130

// Else some GPUs will complain
precision highp float;

uniform vec3 color;
out vec4 outColor;


void main() {
    outColor = vec4(color.xyz, 1.0);
}