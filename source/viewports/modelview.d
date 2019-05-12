module viewports.modelview;
import gtk.GLArea;
import gdk.GLContext;
import gtk.ApplicationWindow;
import gl.shader;
import components.glviewport;
import bindbc.opengl;
import gl.camera;
import math;
import config;
import assets;
import scene.scene;

class ModelingViewport : EditorViewport {
public:
    bool isMovingCamera;

    Vector2 referencePosition;
    float refRotationX;
    float refRotationY;

    Camera camera;
    import std.stdio : writeln;

    this(ApplicationWindow window) {
        super(window);
    }

    override void init() {
        BASIC_SHADER = loadShaderOptimal!("basic");
        LINE_SHADER = loadShaderOptimal!("line");

        camera = new Camera(this);
        camera.changeFocus(Vector3(0, 0, 0), 50);
        camera.rotationX = mathf.radians(25f);
        camera.rotationY = mathf.radians(90f);
    }
    
    override bool onKeyPressEvent(GdkEventKey* key) {
        import gdk.Keysyms;
        if (key.keyval == Keysyms.GDK_Q) {

            if (CONFIG.camera.perspective) {
                this.projectionSwitch.ortho.setActive(true);
            } else {
                this.projectionSwitch.persp.setActive(true);
            }
        }
        return true;
    }

    override bool onButtonPressEvent(GdkEventButton* button) {
        if (!isMovingCamera && button.button == 2) {
            referencePosition = Vector2(button.x, button.y);
            refRotationX = camera.rotationX;
            refRotationY = camera.rotationY;
            isMovingCamera = true;
            return true;
        }
        return false;
    }

    override bool onScrollEvent(GdkEventScroll* scroll) {
        camera.distance += scroll.deltaY;
        return false;
    }

    override bool onButtonReleaseEvent(GdkEventButton* button) {
        if (button.button == 2) {
            isMovingCamera = false;
        }
        return false;
    }

    override bool onMotionNotifyEvent(GdkEventMotion* motion) {
        if (isMovingCamera) {
            camera.rotationX = refRotationX;
            camera.rotationY = refRotationY;

            if (!CONFIG.camera.invertX) camera.rotationX  -= mathf.radians(referencePosition.y-motion.y);
            else camera.rotationX += mathf.radians(referencePosition.y-motion.y);

            if (!CONFIG.camera.invertY) camera.rotationY -= mathf.radians(referencePosition.x-motion.x);
            else camera.rotationY += mathf.radians(referencePosition.x-motion.x);
            return true;
        }
        return false;
    }

    override void update() {
        // camera.position = Vector3(20, 21, 20);
        // camera.lookAt(Vector3(0, 0, 0));
        camera.transformView();
        camera.update();
    }

    override bool draw(GLContext context, GLArea area) {
        if (SCENE !is null) {
            if (SCENE.sceneReloaded()) {
                SCENE.setContext(this.viewport);
                Vector3 start = SCENE.rootNode.children[0].startPosition;
                Vector3 end = SCENE.rootNode.children[0].endPosition;
                camera.changeFocus(start+((end-start)/2), 50);
            }
            SCENE.update();
            SCENE.render(camera);
        }
        return true;
    }
}

ShaderProgram loadShaderOptimal(string name)() {
    version(RELEASE) {
        return ShaderProgram.fromFilesCompileTime!(name~".vert", name~".frag")();
    } else {
        Shader vert = Shader.loadFromFile("shaders/"~name~".vert");
        Shader frag = Shader.loadFromFile("shaders/"~name~".frag");
        return ShaderProgram(vert, frag);
    }
}