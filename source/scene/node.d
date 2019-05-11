module scene.node;
public import math;

class Node {
    /// Wether this node is visible in the viewport
    bool visible;

    /// Position of the node
    Vector3 position;

    /// Scale of the node
    Vector3 scale;

    /// Rotation of the node
    Quaternion rotation;
    
    /// Children attached to the node
    Node[] children;

    this() {
        Vector3 test = Vector3(0, 0, 0);
    }

    /// Function call for updating this node and its subnodes recursively
    final void update() {
        foreach(child; children) {
            child.update();
        }
        updateBuffer();
    }

    abstract Matrix4x4 createMatrix();

    abstract void updateBuffer();

    abstract void render();

    /// Virtual post-rendering function
    void postRender() {

    }
}