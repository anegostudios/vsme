module scene.nodes.root;
import scene.node;
import math;

/++
    The root node of a scene
+/
class RootNode : Node {
public:
    this() {
        super(NodeType.RootNode);
        this.name = "root";
    }

    override Matrix4x4 transform() {
        return Matrix4x4.identity;
    }

    override void updateBuffer() {
        foreach(child; children) {
            updateBuffer();
        }
    }

    override void render() {
        foreach(child; children) {
            render();
        }
    }
}