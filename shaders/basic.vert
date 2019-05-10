#version 130

// Else some GPUs will complain
precision highp float;
in vec3 position;

out vec3 exPosition;

void main () {
    gl_Position = vec4(position, 1.0);
    exPosition = position;
}