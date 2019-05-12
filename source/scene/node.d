module scene.node;
public import math;
import std.format;

enum NodeType : ubyte {
    CorruptNode = 0,
    ElementNode = 1,
    LinkNode = 2,

    RootNode = 255
}

class Node {
    /// Name of node
    string name;

    /// Type of node
    ubyte typeId;

    /// Wether this node is visible in the viewport
    bool visible;

    /// Position of the node
    Vector3 startPosition;

    /// Position of the node
    Vector3 endPosition;

    /// Origin vector
    Vector3 origin;

    /// Rotation of the node
    Quaternion rotation;
    
    /// Children attached to the node
    Node[] children;

    /// Legacy tint index.
    int legacyTint;

    this(NodeType type) {
        this.typeId = type;
    }

    /// Function call for updating this node and its subnodes recursively
    final void update() {
        foreach(child; children) {
            child.update();
        }
        updateBuffer();
    }

    abstract Matrix4x4 transform();

    abstract void updateBuffer();

    abstract void render();

    /// Virtual post-rendering function
    void postRender() {}

    string toString(size_t index) {
        string children = "";
        foreach(child; this.children) {
            children ~= child.toString(index+1);
        }
        return "%s> %s\n%s".format(tabIndexToString(index), this.name, children.length > 0 ? "%s> children:\n%s".format(tabIndexToString(index), children) : "");
    }
}

string tabIndexToString(size_t index) {
    import std.range : repeat;
    string output = "";
    foreach (tab; "\t".repeat(index)) output ~= tab;
    return output;
}