module scene.scene;
import scene.node;
import scene.nodes;
import vsformat;
import std.stdio;
import gl.camera;
import std.math;
import utils.lineguide;
import config;


class Scene {
private:
    bool shouldInit = true;
    GLArea ctx;

public:
    Node focus;
    bool hasFocusChanged = true;

    Node rootNode;
    string[string] textures;

    this(bool setupBasic = false) {
        rootNode = new RootNode();
        if (setupBasic) {
            rootNode.children ~= addNewElement();
            this.focus = rootNode.children[0];
        }
    }

    ~this() {
        import core.memory : GC;
        destroy(rootNode);
        GC.collect();
    }

    ElementNode addNewElement(string name = "Cube", Node parent = null) {
        ElementNode elmNode = new ElementNode(rootNode);
        elmNode.startPosition = Vector3(0, 0, 0);
        elmNode.endPosition = Vector3(16, 16, 16);
        elmNode.name = name;
        elmNode.visible = true;
        elmNode.parent = parent !is null ? parent : rootNode;
        return elmNode;
    }

    bool sceneReloaded() {
        return shouldInit;
    }

    void setContext(GLArea area) {
        this.ctx = area;
    }

    void changeFocus(Node node) {
        this.focus = node;
        hasFocusChanged = true;
    }

    void setCameraFocalPoint(Camera camera) {
        if (focus is null) {
            focus = this.rootNode;
        }
        Vector3 start = this.focus.startPosition;
        Vector3 end = this.focus.endPosition;
        Vector3 center = start+((end-start)/2);
        Matrix4x4 posVector = this.focus.center_model();
        camera.changeFocus(Vector3(posVector[0][3], posVector[1][3], posVector[2][3]), camera.distance);
        hasFocusChanged = false;
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
        if (DIR_GUIDE is null) {
            DIR_GUIDE = new LineGuide(camera);
        }
        rootNode.render(camera);
        DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(8, 0, 0), Vector3(.8f, 0, 0), Matrix4x4.identity(), 8f);
        DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(0, 8, 0), Vector3(0, .8f, 0), Matrix4x4.identity(), 8f);
        DIR_GUIDE.drawLine(Vector3(0, 0, 0), Vector3(0, 0, 8), Vector3(0, 0, .8f), Matrix4x4.identity(), 8f);
        
        // Make sure if the color is .
        Vector3 bgVec = Vector3(CONFIG.backgroundColor);
        Vector3 hfVec = Vector3(.5f);
        Vector3 drColor = bgVec;
        if (drColor > hfVec) {
            drColor -= Vector3(0.1f);
        } else {
            drColor += Vector3(0.1f);
        }

        if (CONFIG.render.showHelperGrid) {
            foreach(x; 0..17) {
                foreach(z; 0..17) {
                    DIR_GUIDE.drawSquare(Vector3((x-8)*16, 0, (z-8)*16), Vector3(((x-8)+1)*16, 0, ((z-8)+1)*16), drColor, Matrix4x4.identity(), 1f);
                }
            }
        }
        if (CONFIG.render.showBlockHeightHelper) {
            DIR_GUIDE.drawSquare(Vector3(0, 16, 0), Vector3(16, 16, 16), drColor, Matrix4x4.identity(), 1f);
        }
        
        /// Disable depth buffer for post-rendering
        glClear(GL_DEPTH_BUFFER_BIT);
        glDisable(GL_DEPTH);
        if (CONFIG.render.showRotationCenter) {
            DIR_GUIDE.drawPoint(camera.origin, Vector3(0, 0, 0), 5f);
        }

        rootNode.postRender(camera);
        /// TODO: make a Dot guide
        glEnable(GL_DEPTH);
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
    
    foreach(elem; shape.elements) {
        scene.rootNode.children ~= nodeFromJElement(elem, scene.rootNode);
    }

    SCENE = scene;
    SCENE.focus = scene.rootNode.children[0];

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

    // n.rotation = Vector3(
    //     jelement.rotationX == float.nan ? 0 : jelement.rotationX, 
    //     jelement.rotationY == float.nan ? 0 : jelement.rotationY, 
    //     jelement.rotationZ == float.nan ? 0 : jelement.rotationZ);
    if (!isNaN(jelement.rotationX)) {
        n.rotation.x = jelement.rotationX;
    }
    if (!isNaN(jelement.rotationY)) {
        n.rotation.y = jelement.rotationY;
    }
    if (!isNaN(jelement.rotationZ)) {
        n.rotation.z = jelement.rotationZ;
    }

    n.visible = true;
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

__gshared static LineGuide DIR_GUIDE;