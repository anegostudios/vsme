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
    Camera camera;
    import std.stdio : writeln;

    this(ApplicationWindow window) {
        super(window);
    }

    override void init() {
        version(RELEASE) {
            BASIC_SHADER = ShaderProgram.fromFilesCompileTime!("basic.vert", "basic.frag")();
        } else {
            Shader vert = Shader.loadFromFile("shaders/basic.vert");
            Shader frag = Shader.loadFromFile("shaders/basic.frag");
            BASIC_SHADER = ShaderProgram(vert, frag);
        }

        camera = new Camera(this);
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

    override void update() {
        camera.position = Vector3(20, 21, 20);
        camera.lookAt(Vector3(0, 0, 0));
        camera.update();
    }

    override bool draw(GLContext context, GLArea area) {
        if (SCENE !is null) {
            if (SCENE.sceneReloaded()) {
                SCENE.setContext(this.viewport);
            }
            SCENE.update();
            SCENE.render(camera);
        }
        return true;
    }
}