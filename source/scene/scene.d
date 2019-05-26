/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
    alias callbackDelegate = void delegate();
    bool shouldInit = true;
    GLArea ctx;

    static __gshared callbackDelegate[] loadCallbacks;
    static __gshared callbackDelegate[] focusChangeCallbacks;

    void callLoadCallbacks() {
        if (loadCallbacks is null) return;
        foreach(loadCallback; loadCallbacks) {
            loadCallback();
        }
    }

public:
    string outputPath;

    Node focus;
    bool hasFocusChanged = true;

    Node rootNode;
    string[string] textures;

    this(bool setupBasic = false) {
        rootNode = new RootNode();
        if (setupBasic) {
            rootNode.children ~= addNewElement();
            this.changeFocus(rootNode.children[0]);
            if (loadCallbacks is null) return;
            callLoadCallbacks();
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
        elmNode.origin = Vector3(8, 8, 8);
        elmNode.name = name;
        elmNode.visible = true;
        elmNode.parent = parent !is null ? parent : rootNode;
        return elmNode;
    }

    static void addLoadCallback(callbackDelegate callback) {
        loadCallbacks ~= callback;
    }

    static void addRefocusCallback(callbackDelegate callback) {
        focusChangeCallbacks ~= callback;
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

        if (focusChangeCallbacks is null) return;
        foreach(focusChangeCallback; focusChangeCallbacks) {
            focusChangeCallback();
        }
    }

    void setCameraFocalPoint(Camera camera) {
        if (focus is null) {
            changeFocus(this.rootNode);
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
            DIR_GUIDE.drawPoint(camera.origin, Vector3(0, 0, 0), Matrix4x4.identity(), 8f);
        }

        rootNode.postRender(camera);
        /// TODO: make a Dot guide
        glEnable(GL_DEPTH);
    }

    override string toString() {
        return "Scene:\n" ~ rootNode.toFmtString(1);
    }
}

void exportToVSMCFile(string path) {
    import fio = std.file;
    JShape shape;
    shape.textures = SCENE.textures;
    shape.elements = jElementFromNode(SCENE.rootNode).children;
    fio.write(path, shape.toJson());  
}

JElement jElementFromNode(Node node) {
    JElement element;
    foreach(child; node.children) {
        element.children ~= jElementFromNode(child);
    }
    if (node.parent is null) return element;

    element.name = node.name;
    element.from = [node.startPosition.x, node.startPosition.y, node.startPosition.z];
    element.to = [node.endPosition.x, node.endPosition.y, node.endPosition.z];

    element.rotationOrigin = [node.origin.x, node.origin.y, node.origin.z];
    element.rotationX = node.rotation.x;
    element.rotationY = node.rotation.y;
    element.rotationZ = node.rotation.z;
    element.tintIndex = node.legacyTint;

    if (is(node : ElementNode)) {
        foreach(key, face; (cast(ElementNode)node).faces) {
            JFace fc;
            element.faces[key] = fc;
            element.faces[key].texture = face.texture;
            element.faces[key].uv = [face.uvStart.x, face.uvEnd.y, face.uvEnd.x, face.uvEnd.y];
            element.faces[key].enabled = face.enabled;
        }
    }
    return element;
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
    SCENE.changeFocus(scene.rootNode.children[0]);
    SCENE.outputPath = path;

    SCENE.callLoadCallbacks();
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
    // TODO: implement VSME/Vintage Studio format for extra features.
}

__gshared static Scene SCENE;

__gshared static LineGuide DIR_GUIDE;