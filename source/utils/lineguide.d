/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
        0, 0, 1,

        0, 0, 0,
        0, 0, 0,

        0, 0, 0,
        0, 0, 0,

        0, 0, 0,
        0, 0, 0,
    ];

    Camera camera;

public:
    this(Camera camera) {
        this.camera = camera;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, verts.length*float.sizeof, verts.ptr, GL_STATIC_DRAW);

        mvpMatrix = LINE_SHADER.getUniform("mvp");
        color = LINE_SHADER.getUniform("color");
    }

    public void drawPoint(Vector3 at, Vector3 color, Matrix4x4 model, float lineWidth = 1f) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        verts = [
            at.x, at.y, at.z
        ];

        glBufferSubData(GL_ARRAY_BUFFER, 0, verts.length*float.sizeof, verts.ptr);
        glPointSize(lineWidth);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(0);
        LINE_SHADER.use();
        LINE_SHADER.setUniform(this.mvpMatrix, camera.mvp*model);
        LINE_SHADER.setUniform(this.color, color);
        glDrawArrays(GL_POINTS, 0, 1);
        glDisableVertexAttribArray(0);
    }

    public void drawLine(Vector3 from, Vector3 to, Vector3 color, Matrix4x4 model, float lineWidth = 1f) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        verts = [
            from.x, from.y, from.z,
            to.x, to.y, to.z
        ];
        glBufferSubData(GL_ARRAY_BUFFER, 0, verts.length*float.sizeof, verts.ptr);
        glLineWidth(lineWidth);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(0);
        LINE_SHADER.use();
        LINE_SHADER.setUniform(this.mvpMatrix, camera.mvp*model);
        LINE_SHADER.setUniform(this.color, color);
        glDrawArrays(GL_LINES, 0, 2);
        glDisableVertexAttribArray(0);
        
    }

    public void drawSquare(Vector3 from, Vector3 to, Vector3 color, Matrix4x4 model, float lineWidth = 1f) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);

        // 0 0
        // 0 1
        // 1 1
        // 1 0
        verts = [
            from.x, from.y, from.z,
            from.x, to.y, to.z,
            
            from.x, to.y, to.z,
            to.x, to.y, to.z,

            to.x, to.y, to.z,
            to.x, from.y, from.z,

            to.x, from.y, from.z,
            from.x, from.y, from.z
        ];
        glBufferSubData(GL_ARRAY_BUFFER, 0, verts.length*float.sizeof, verts.ptr);
        glLineWidth(lineWidth);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(0);
        LINE_SHADER.use();
        LINE_SHADER.setUniform(this.mvpMatrix, camera.mvp*model);
        LINE_SHADER.setUniform(this.color, color);
        glDrawArrays(GL_LINES, 0, 8);
        glDisableVertexAttribArray(0);
        
    }
}