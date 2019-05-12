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
        this.startPosition = Vector3(0, 0, 0);
        this.endPosition = Vector3(0, 0, 0);
    }

    override Matrix4x4 transform() {
        return Matrix4x4.identity;
    }

    override void updateBuffer() {
        // There's no buffer in the root node
    }

    override void render(Camera camera) {
        foreach(child; children) {
            child.render(camera);
        }
    }
}