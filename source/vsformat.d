/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module vsformat;
import asdf;

public:

/// Output JSON shape that vintage story can read
struct JShape {
public:
    /// Width of texture
    size_t textureWidth;

    /// Height of texture
    size_t textureHeight;

    /// The textures this shape has access to
    string[string] textures;

    /// The elements this shape is made out of.
    JElement[] elements;

    /// Converts this JShape in to a json object
    string toJson() {
        return serializeToJsonPretty(this);
    }
}

/// Output JSON element that vintage story can read
struct JElement {
public:
    /// Name of the element
    string name;

    /// Coordinates where this element begins
    float[3] from;

    /// Coordinates where this element ends
    float[3] to;

    /// Dictionary of attached faces
    JFace[string] faces;

    /// Child elements
    JElement[] children;

    /// Origin of rotation for this element
    float[] rotationOrigin;

    /// The amount of rotation on the X axis
    float rotationX;

    /// The amount of rotation on the Y axis
    float rotationY;

    /// The amount of rotation on the Z axis
    float rotationZ;

    /// The tint index of the element
    int tintIndex;
}

/// Output JSON face that vintage story can read
struct JFace {
public:
    /// The texture to be applied to the face
    string texture;

    /// The UV coordinates of the subtexture for the face
    float[4] uv;

    /// Wether this face is enabled or not
    bool enabled;
}

/// Creates a new shape from a json string
JShape shapeFromJson(string jsonString) {
    return jsonString.deserialize!JShape();
}