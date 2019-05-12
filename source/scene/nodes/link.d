module scene.nodes.link;
import scene.node;
import math;

class LinkNode : Node {
public:
    this() {
        super(NodeType.LinkNode);
    }

    override Matrix4x4 transform() {
        return Matrix4x4.identity;
    }

    override void updateBuffer() {

    }

    override void render() {

    }
}