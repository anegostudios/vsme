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

class ModelingViewport : EditorViewport {
public:
    Camera camera;
    GLuint vao;
    GLuint vbo;
    GLuint ibo;
    GLuint mvpMatrix;
    ShaderProgram basicShader;
    import std.stdio : writeln;

    float[] verts;

    this(ApplicationWindow window) {
        super(window);
    }

    override void init() {

        camera = new Camera(this);

        verts = generateCube(Vector3(0, 0, 0), Vector3(1, 1, 1), Matrix3x3.identity());

        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        glGenBuffers(1, &ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, cubeIndices.length * uint.sizeof, cubeIndices.ptr, GL_STATIC_DRAW);

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, verts.length*float.sizeof, verts.ptr, GL_STATIC_DRAW);
        version(RELEASE) {
            basicShader = ShaderProgram.fromFilesCompileTime!("basic.vert", "basic.frag")();
        } else {
            Shader vert = Shader.loadFromFile("shaders/basic.vert");
            Shader frag = Shader.loadFromFile("shaders/basic.frag");
            basicShader = ShaderProgram(vert, frag);
        }

        mvpMatrix = basicShader.getUniform("mvp");
        camera.position = Vector3(0, 0, 5);
        camera.lookat(Vector3(0, 0, 0));
        camera.update();
    }
    
    override bool onButtonReleaseEvent(GdkEventButton* button) {
        if (button.button == 2) {
            CONFIG.camera.perspective = !CONFIG.camera.perspective;
        }
        return true;
    }

    override bool onKeyPressEvent(GdkEventKey* key) {
        import gdk.Keysyms;
        if (key.keyval == Keysyms.GDK_Q) {
            CONFIG.camera.perspective = !CONFIG.camera.perspective;
        }
        return true;
    }

    override void update() {
        camera.position = Vector3(0, 3, 3);
        camera.lookat(Vector3(.5, .5, .5));
        camera.update();
    }

    override bool draw(GLContext context, GLArea area) {
        glEnableVertexAttribArray(0);
        basicShader.use();
        basicShader.setUniform(mvpMatrix, camera.mvp);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glDrawElements(GL_TRIANGLES, cast(int)cubeIndices.length, GL_UNSIGNED_INT, null);
        glDisableVertexAttribArray(0);
        return true;
    }
}