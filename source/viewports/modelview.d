module viewports.modelview;
import gtk.GLArea;
import gdk.GLContext;
import gl.shader;
import components.glviewport;
import bindbc.opengl;


class ModelingViewport : EditorViewport {
public:
    GLuint vao;
    GLuint vbo;
    ShaderProgram basicShader;
    import std.stdio : writeln;

    float[] verts = [ 
        -1f, -1f,  0f,  
        1f,  -1f,  0f,
        0f,   1f,  0f,
    ];

    this() {
        super();
    }

    override void init() {

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
    }
    
    override bool draw(GLContext context, GLArea area) {
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        basicShader.use();
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glDisableVertexAttribArray(0);
        return false;
    }
}