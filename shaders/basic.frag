#version 130

// Else some GPUs will complain
precision highp float;
in vec3 exPosition;
out vec4 outColor;

void main() {
    outColor = vec4(exPosition+.5, 1.0);
}