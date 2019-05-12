module scene.scene;
import scene.node;
import scene.nodes;
import vsformat;
import std.stdio;
import gl.camera;

class Scene {
private:
    bool shouldInit = true;
    GLArea ctx;

public:
    Node rootNode;
    string[string] textures;
    
    ~this() {
        import core.memory : GC;
        destroy(rootNode);
        GC.collect();
    }

    bool sceneReloaded() {
        return shouldInit;
    }

    void setContext(GLArea area) {
        this.ctx = area;
    }

    void update() {
        if (shouldInit) {
            rootNode.setContext(this.ctx);
            rootNode.init();
            shouldInit = false;
        }
        rootNode.update();
        rootNode.updateBuffer();
    }

    void render(Camera camera) {
        rootNode.render(camera);
        rootNode.postRender(camera);
    }

    override string toString() {
        return "Scene:\n" ~ rootNode.toString(1);
    }
}

void loadFromVSMCFile(string path) {
    if (SCENE !is null) destroy(SCENE);

    import std.file : readText;
    JShape shape = shapeFromJson(readText(path));
    Scene scene = new Scene();
    
    scene.rootNode = new RootNode();
    foreach(elem; shape.elements) {
        scene.rootNode.children ~= nodeFromJElement(elem);
    }

    SCENE = scene;

    writeln("Loaded scene!\n\n", scene);
}

Node nodeFromJElement(JElement jelement, Node parent = null) {
    ElementNode n = new ElementNode(parent);
    
    n.name = jelement.name;

    // Verticies
    n.startPosition = Vector3(jelement.from[0], jelement.from[1], jelement.from[2]);
    n.endPosition = Vector3(jelement.to[0], jelement.to[1], jelement.to[2]);
    if(jelement.rotationOrigin.length > 0) {
        n.origin = Vector3(jelement.rotationOrigin[0], jelement.rotationOrigin[1], jelement.rotationOrigin[2]);
    }

    n.rotation = Quaternion.identity();
    n.rotation.rotatex(jelement.rotationX);
    n.rotation.rotatey(jelement.rotationY);
    n.rotation.rotatez(jelement.rotationZ);

    n.legacyTint = jelement.tintIndex;

    foreach(key, face; jelement.faces) {
        n.faces[key] = new Face();
        n.faces[key].texture = face.texture;
        n.faces[key].uvStart = Vector2(face.uv[0], face.uv[1]);
        n.faces[key].uvEnd = Vector2(face.uv[2], face.uv[3]);
        n.faces[key].enabled = face.enabled;
    }

    foreach(child; jelement.children) {
        n.children ~= nodeFromJElement(child, n);
    }
    return n;
}

void loadFromVSMEProject(string path) {

}

__gshared static Scene SCENE;