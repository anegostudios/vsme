#version 130

// Else some GPUs will complain
precision highp float;

in vec3 position;
uniform mat4 mvp;

void main () {
    gl_Position = mvp * vec4(position, 1);
}