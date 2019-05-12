module math;
public import linalg = gl3n.linalg;
public import mathf = gl3n.math;
alias Matrix4x4 = linalg.Matrix!(float, 4, 4);
alias Matrix3x3 = linalg.Matrix!(float, 3, 3);
alias Vector3 = linalg.Vector!(float, 3);
alias Vector2 = linalg.Vector!(float, 2);
alias Quaternion = linalg.Quaternion!float;

float[] generateCube(Vector3 startPos, Vector3 endPos, Matrix3x3 transform) {
    // float[] translatedVerts = new float[](cubeVerts.length);
    // foreach(i; 0..cubeVerts.length/3) {
    //     size_t offs = i*3;
    //     Matrix3x3 matr = Matrix3x3.identity().translate(Vector3(cubeVerts[i], cubeVerts[i+1], cubeVerts[i+2]));
    //     matr *= transform;

    //     Vector3 ovec = Vector3(1, 1, 1) * matr;
    //     translatedVerts[i] = ovec.x;
    //     translatedVerts[i+1] = ovec.y;
    //     translatedVerts[i+2] = ovec.z;
    // }
    // return translatedVerts;
    return cubeVerts;
}

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