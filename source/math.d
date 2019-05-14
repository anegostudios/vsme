/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module math;
public import linalg = gl3n.linalg;
public import mathf = gl3n.math;
alias Matrix4x4 = linalg.Matrix!(float, 4, 4);
alias Matrix3x3 = linalg.Matrix!(float, 3, 3);
alias Vector4 = linalg.Vector!(float, 4);
alias Vector3 = linalg.Vector!(float, 3);
alias Vector2 = linalg.Vector!(float, 2);
alias Quaternion = linalg.Quaternion!float;

float[] generateCube(Vector3 startPos, Vector3 endPos) {
    float[] verticies = new float[](cubeVerts.length);
    foreach(i; 0..verticies.length/3) {
        size_t offset = i*3;
        verticies[offset] = cubeVerts[offset] == 0 ? startPos.x : endPos.x;
        verticies[offset+1] = cubeVerts[offset+1] == 0 ? startPos.y : endPos.y;
        verticies[offset+2] = cubeVerts[offset+2] == 0 ? startPos.z : endPos.z;
    }
    return verticies;
}


private __gshared static float[] cubeVerts = [
    // North
    0, 0, 0,
    0, 1, 0,
    1, 1, 0,
    1, 0, 0,

    // East
    1, 0, 1,
    1, 0, 0,
    1, 1, 0,
    1, 1, 1,

    // South
    0, 0, 1,
    1, 0, 1,
    1, 1, 1,
    0, 1, 1,
    
    // West
    0, 0, 0,
    0, 0, 1,
    0, 1, 1,
    0, 1, 0,

    // Top
    1, 1, 0,
    0, 1, 0,
    0, 1, 1,
    1, 1, 1,

    // Bottom
    0, 0, 0,
    1, 0, 0,
    1, 0, 1,
    0, 0, 1
];

public __gshared static float[] brightnessMap = [
    // North
    .95, .95, .95,
    .95, .95, .95,
    .95, .95, .95,
    .95, .95, .95,

    // East
    .9, .9, .9,
    .9, .9, .9,
    .9, .9, .9,
    .9, .9, .9,

    // South
    .95, .95, .95,
    .95, .95, .95,
    .95, .95, .95,
    .95, .95, .95,

    // West
    .9, .9, .9,
    .9, .9, .9,
    .9, .9, .9,
    .9, .9, .9,

    // Top
    1, 1, 1,
    1, 1, 1,
    1, 1, 1,
    1, 1, 1,

    // Bottom
    .7, .7, .7,
    .7, .7, .7,
    .7, .7, .7,
    .7, .7, .7
];

public __gshared static uint[] cubeIndices = [
    // North
    0u,  1u,  2u,
    0u,  2u,  3u,

    // East
    4u,  5u,  6u,
    4u,  6u,  7u,

    // East
    8u,  9u,  10u,
    8u, 10u,  11u,

    // South
    12u, 13u, 14u,
    12u, 14u, 15u,

    // West
    16u, 17u, 18u,
    16u, 18u, 19u,

    // Top
    20u, 21u, 22u,
    20u, 22u, 23u,

    // Bottom
    24u, 25u, 26u,
    24u, 26u, 27u
];

private __gshared static int[] uvCoords = [
    // North
    1, 1,
    1, 0,
    0, 0,
    0, 1,

    // East
    0, 1,
    1, 1,
    1, 0,
    0, 0,

    // South
    0, 1,
    1, 1,
    1, 0,
    0, 0,

    // West
    0, 1,
    1, 1,
    1, 0,
    0, 0,

    // Top
    1, 0,
    0, 0,
    0, 1,
    1, 1,

    // Bottom
    1, 0,
    0, 0,
    0, 1,
    1, 1
];