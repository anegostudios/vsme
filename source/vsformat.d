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
        return serializeToJson!JShape(this);
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