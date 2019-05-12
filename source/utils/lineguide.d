module utils.lineguide;
import bindbc.opengl;
import gl.camera;
import assets;
import math;

/// Draws lines
class LineGuide {
private:
    GLuint vao;
    GLuint vbo;
    GLuint mvpMatrix;
    GLuint color;
    float[] verts = [
        0, 0, 0,
        0, 0, 1
    ];

    Camera camera;

public:
    this(Camera camera) {
        this.camera = camera;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, verts.length*float.sizeof, verts.ptr, GL_DYNAMIC_DRAW);

        mvpMatrix = LINE_SHADER.getUniform("mvp");
        color = LINE_SHADER.getUniform("color");
    }

    public void drawLine(Vector3 from, Vector3 to, Vector3 color, Matrix4x4 model, float lineWidth = 1f) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        verts = [
            from.x, from.y, from.z,
            to.x, to.y, to.z
        ];
        glBufferSubData(GL_ARRAY_BUFFER, 0, verts.length*float.sizeof, verts.ptr);
        
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(0);
        LINE_SHADER.use();
        LINE_SHADER.setUniform(this.mvpMatrix, camera.mvp*model);
        LINE_SHADER.setUniform(this.color, color);
        glDrawArrays(GL_LINES, 0, 6);
        glDisableVertexAttribArray(0);
        
    }
}