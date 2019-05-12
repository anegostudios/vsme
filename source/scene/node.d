module scene.node;
public import math;
public import assets;
public import bindbc.opengl;
public import gl.camera;
public import gtk.GLArea;
import std.format;
import std.stdio;

enum NodeType : ubyte {
    CorruptNode = 0,
    ElementNode = 1,
    LinkNode = 2,

    RootNode = 255
}

class Node {
private:
    Vector3 prevStart;
    Vector3 prevEnd;

protected:
    GLuint vao;
    GLuint vbo;
    GLuint ibo;
    GLArea ctx;

public:
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
    
    Node parent;

    /// Children attached to the node
    Node[] children;

    /// Legacy tint index.
    int legacyTint;

    this(NodeType type, Node parent = null) {
        this.typeId = type;
        this.parent = parent;
    }

    final void setContext(GLArea context) {
        this.ctx = context;
        foreach(child; children) {
            child.setContext(context);
        }
    }

    /// Function call for updating this node and its subnodes recursively
    final void update() {
        foreach(child; children) {
            child.update();
        }
        // Update buffer if the position/size changed.
        if (prevStart != startPosition || prevEnd != endPosition) {
            updateBuffer();
        }

        // Update the size/position state
        prevStart = Vector3(startPosition.x, startPosition.y, startPosition.z);
        prevEnd = Vector3(endPosition.x, endPosition.y, endPosition.z);
    }

    void init() {
        // Does nothing unless overwritten
        foreach(child; children) {
            child.init();
        }
    }

    abstract Matrix4x4 transform();

    abstract void updateBuffer();

    abstract void render(Camera camera);

    Matrix4x4 model() {
        Matrix4x4 rotationMatrix = rotation.to_matrix!(4, 4);
        Matrix4x4 originMatrix = Matrix4x4.translation(origin);
        Matrix4x4 minusOriginMatrix = Matrix4x4.translation(-origin);
        Matrix4x4 startMatrix = Matrix4x4.translation(startPosition);

        Matrix4x4 modelMatrix = Matrix4x4.identity();
        if (originMatrix.ok) modelMatrix *= originMatrix;
        if (rotationMatrix.ok) modelMatrix *= rotationMatrix;
        if (minusOriginMatrix.ok) modelMatrix *= minusOriginMatrix;
        if (startMatrix.ok) modelMatrix *= startMatrix;

        if (parent !is null) {
            modelMatrix = parent.model * modelMatrix;
        }
        return modelMatrix;
    }

    /// Virtual post-rendering function
    void postRender(Camera camera) {
        foreach(child; children) {
            child.postRender(camera);
        }
    }

    string toString(size_t index) {
        string children = "";
        foreach(child; this.children) {
            children ~= child.toString(index+2);
        }
        string startPosText = "%s> start: %s\n".format(tabIndexToString(index+1), startPosition);
        string endPosText = "%s> end:   %s\n".format(tabIndexToString(index+1), endPosition);
        
        string chldText = children.length > 0 ? "%s> children:\n%s".format(tabIndexToString(index+1), children) : "";

        return "%s> %s\n%s%s%s".format(tabIndexToString(index), this.name, startPosText, endPosText, chldText);
    }
}

string tabIndexToString(size_t index) {
    import std.range : repeat;
    string output = "";
    foreach (tab; "| ".repeat(index)) output ~= tab;
    return output;
}