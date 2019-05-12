#version 130

// Else some GPUs will complain
precision highp float;

in vec3 position;
in vec3 brightness;

out vec3 brightnessMap;
uniform mat4 mvp;

void main () {
    gl_Position = mvp * vec4(position, 1);
    brightnessMap = brightness;
}