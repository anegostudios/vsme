module scene.node;
public import math;
public import assets;
public import bindbc.opengl;
public import gl.camera;
public import gtk.GLArea;
import std.format;
import std.stdio;
import scene.scene;

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
    Vector3 startPosition = Vector3(0, 0, 0);

    /// Position of the node
    Vector3 endPosition = Vector3(0, 0, 0);

    /// Origin vector
    Vector3 origin = Vector3(0, 0, 0);

    /// Rotation of the node
    Vector3 rotation = Vector3(0, 0, 0);
    
    Node parent;

    /// Children attached to the node
    Node[] children = [];

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

    void render(Camera camera) {
        if (SCENE.focus is this) {
            Vector3 size = endPosition-startPosition;

            DIR_GUIDE.drawSquare(Vector3(0, 0, 0), Vector3(size.x, 0, size.z), Vector3(.7, .7, 1f), model, 5f);
            DIR_GUIDE.drawSquare(Vector3(0, 0, 0), Vector3(size.x, size.y, 0), Vector3(.7, .7, 1f), model, 5f);

            DIR_GUIDE.drawSquare(Vector3(0, size.y, 0), Vector3(size.x, size.y, size.z), Vector3(.7, .7, 1f), model, 5f);
            DIR_GUIDE.drawSquare(Vector3(0, 0, size.z), Vector3(size.x, size.y, size.z), Vector3(.7, .7, 1f), model, 5f);
        }
    }

    Matrix4x4 model() {
        Matrix4x4 rotationMatrix = Matrix4x4.identity();
        rotationMatrix.rotatex(mathf.radians(rotation.x));
        rotationMatrix.rotatey(mathf.radians(rotation.y));
        rotationMatrix.rotatez(mathf.radians(rotation.z));
        
        Matrix4x4 originMatrix = Matrix4x4.translation(origin);
        Matrix4x4 minusOriginMatrix = Matrix4x4.translation(-origin);
        Matrix4x4 startMatrix = Matrix4x4.translation(startPosition);

        Matrix4x4 modelMatrix = Matrix4x4.identity();
        if (originMatrix.isFinite) modelMatrix *= originMatrix;
        if (rotationMatrix.isFinite) modelMatrix *= rotationMatrix;
        if (minusOriginMatrix.isFinite) modelMatrix *= minusOriginMatrix;
        if (startMatrix.isFinite) modelMatrix *= startMatrix;

        if (parent !is null) {
            modelMatrix = parent.model * modelMatrix;
        }
        return modelMatrix;
    }


    Matrix4x4 center_model() {
        Matrix4x4 rotationMatrix = Matrix4x4.identity();
        rotationMatrix.rotatex(mathf.radians(rotation.x));
        rotationMatrix.rotatey(mathf.radians(rotation.y));
        rotationMatrix.rotatez(mathf.radians(rotation.z));

        Vector3 halfSize = (endPosition-startPosition)/2;
        
        Matrix4x4 originMatrix = Matrix4x4.translation(origin);
        Matrix4x4 minusOriginMatrix = Matrix4x4.translation(-origin);
        Matrix4x4 startMatrix = Matrix4x4.translation(startPosition);
        Matrix4x4 halfSizeMatrix = Matrix4x4.translation(halfSize);
        Matrix4x4 minusHalfSizeMatrix = Matrix4x4.translation(-halfSize);

        Matrix4x4 modelMatrix = Matrix4x4.identity();
        if (originMatrix.isFinite) modelMatrix *= originMatrix;
        if (rotationMatrix.isFinite) modelMatrix *= rotationMatrix;
        if (halfSizeMatrix.isFinite) modelMatrix *= halfSizeMatrix;
        if (minusOriginMatrix.isFinite) modelMatrix *= minusOriginMatrix;
        if (startMatrix.isFinite) modelMatrix *= startMatrix;

        if (parent !is null) {
            modelMatrix = parent.model * modelMatrix;
        }
        return modelMatrix;
    }

    void removeChild(Node child) {
        if (children.length == 0) return;
        int i = 0;
        Node c = children[i];
        
        do {
            if (c == child) {
                writefln("Destroying %s...", child.name);
                destroy(children[i]);
                children[i] = null;
                pruneChildren();
                return;
            }
            if (i+1 < children.length) { 
                i++;
                c = children[i];
            }
            else c = null;
        } while(c !is null);
        writefln("WARNING: %s was not found in %s!...", child.name, this.name);
    }

    void selfDestruct() {
        if (parent is null) return;
        parent.removeChild(this);
    }

    void pruneChildren() {
        for (size_t i = 0; i < children.length; i++) {
            if (children[i] is null) {
                writefln("Removing null offset @ %s.children[%d]", name, i);
                children = children[0..i] ~ children[i+1..$];
                i--;
            }

            // If we're out of range, we're done. 
            if (i >= children.length) return;
        }
    }

    /// Virtual post-rendering function
    void postRender(Camera camera) {
        foreach(child; children) {
            child.postRender(camera);
        }

        if (this is SCENE.focus) {
            DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(.8f, 0, 0), model, 4f);
            DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(0, .8f, 0), model, 4f);
            DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, .8f), model, 4f);

            DIR_GUIDE.drawPoint(this.origin, Vector3(0.976, 0.505, 0.164), model, 6f);
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