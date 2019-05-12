module scene.nodes.element;
import scene.node;
import math;

class Face {
    /// The texture bound to the face
    string texture;

    /// The starting UV coordinate
    Vector2 uvStart;

    /// The ending UV coordinate
    Vector2 uvEnd;

    /// Wether this face should be rendered.
    bool enabled;
}

class ElementNode : Node {
public:
    Face[string] faces;

    this() {
        super(NodeType.ElementNode);
    }

    override Matrix4x4 transform() {
        return Matrix4x4.identity;
    }

    override void updateBuffer() {

    }

    override void render() {

    }
}