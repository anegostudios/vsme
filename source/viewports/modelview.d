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
    GLuint mvpMatrix;
    ShaderProgram basicShader;
    import std.stdio : writeln;

    float[] verts = [ 
        -1.0f,-1.0f,-1.0f, // triangle 1 : begin
        -1.0f,-1.0f, 1.0f,
        -1.0f, 1.0f, 1.0f, // triangle 1 : end
        1.0f, 1.0f,-1.0f, // triangle 2 : begin
        -1.0f,-1.0f,-1.0f,
        -1.0f, 1.0f,-1.0f, // triangle 2 : end
        1.0f,-1.0f, 1.0f,
        -1.0f,-1.0f,-1.0f,
        1.0f,-1.0f,-1.0f,
        1.0f, 1.0f,-1.0f,
        1.0f,-1.0f,-1.0f,
        -1.0f,-1.0f,-1.0f,
        -1.0f,-1.0f,-1.0f,
        -1.0f, 1.0f, 1.0f,
        -1.0f, 1.0f,-1.0f,
        1.0f,-1.0f, 1.0f,
        -1.0f,-1.0f, 1.0f,
        -1.0f,-1.0f,-1.0f,
        -1.0f, 1.0f, 1.0f,
        -1.0f,-1.0f, 1.0f,
        1.0f,-1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        1.0f,-1.0f,-1.0f,
        1.0f, 1.0f,-1.0f,
        1.0f,-1.0f,-1.0f,
        1.0f, 1.0f, 1.0f,
        1.0f,-1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        1.0f, 1.0f,-1.0f,
        -1.0f, 1.0f,-1.0f,
        1.0f, 1.0f, 1.0f,
        -1.0f, 1.0f,-1.0f,
        -1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        -1.0f, 1.0f, 1.0f,
        1.0f,-1.0f, 1.0f
    ];

    this(ApplicationWindow window) {
        super(window);
    }

    override void init() {

        camera = new Camera(this);

        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

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
        camera.position = Vector3(4, 3, -3);
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
        camera.position = Vector3(4, 3, 3);
        camera.lookat(Vector3(0, 0, 0));
        camera.update();
    }

    override bool draw(GLContext context, GLArea area) {
        glEnableVertexAttribArray(0);
        basicShader.use();
        basicShader.setUniform(mvpMatrix, camera.mvp);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glDrawArrays(GL_TRIANGLES, 0, cast(int)(verts.length/3));
        glDisableVertexAttribArray(0);
        return true;
    }
}