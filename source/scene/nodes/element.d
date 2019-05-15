/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module scene.nodes.element;
import scene.node;
import math;
import std.stdio;
import scene.scene;

class Face {
    /// The texture bound to the face
    string texture;

    /// The starting UV coordinate
    Vector2 uvStart;

    /// The ending UV coordinate
    Vector2 uvEnd;

    /// Wether this face should be rendered.
    bool enabled;
}

class ElementNode : Node {
private:
    float[] verts;
    GLuint mvpMatrix;
    GLuint colorVBO;
    GLuint color;

    void genBuffers() {
        // Generate cube and add brightness map
        verts = generateCube(Vector3(0, 0, 0), this.endPosition-this.startPosition);
        writefln("Generating buffer for %s with %d tris...", name, cubeIndices.length/3);

        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        
        glGenBuffers(1, &ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, cubeIndices.length * uint.sizeof, cubeIndices.ptr, GL_STATIC_DRAW);

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, verts.length*float.sizeof, verts.ptr, GL_STATIC_DRAW);

        glGenBuffers(1, &colorVBO);
        glBindBuffer(GL_ARRAY_BUFFER, colorVBO);
        glBufferData(GL_ARRAY_BUFFER, brightnessMap.length*float.sizeof, brightnessMap.ptr, GL_STATIC_DRAW);

        mvpMatrix = BASIC_SHADER.getUniform("mvp");
        color = BASIC_SHADER.getUniform("color");
    }

public:
    Face[string] faces;

    this(Node parent = null) {
        super(NodeType.ElementNode, parent);
    }

    ~this() {
        writefln("(cleanup) Destroying node %s...", name);

        if (this.ctx is null) {
            writefln("WARNING: Failed to clean up node %s, could not find GL context!", name);
            return;
        }

        // Force the context to be current before we delete ANYTHING
        // Otherwise we might delete the main window context...
        this.ctx.makeCurrent();

        // Recursively destroy children
        foreach(child; children) {
            destroy(child);
        }

        // Clean up VAO, VBO and IBO
        glDeleteVertexArrays(1, &vao);
        glDeleteBuffers(1, &vbo);
        glDeleteBuffers(1, &ibo);
    }

    override void init() {
        super.init();

        genBuffers();
        writefln("%s (gl): vao=%d ibo=%d colorVBO=%d vbo=%d mvpMatrix=%d color=%d", name, vao, ibo, colorVBO, vbo, mvpMatrix, color);
    }

    override Matrix4x4 transform() {
        return Matrix4x4.identity;
    }

    override void updateBuffer() {
        verts = generateCube(Vector3(0, 0, 0), this.endPosition-this.startPosition);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferSubData(GL_ARRAY_BUFFER, 0, verts.length*float.sizeof, verts.ptr);
    }

    override void render(Camera camera) {
        super.render(camera);
        foreach(child; children) {
            child.render(camera);
        }

        // If the element is marked invisible, skip the OpenGL rendering calls
        if (!visible) return;

        // Bind the main buffer for the shape
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(0);

        // Bind the buffer for the color
        glBindBuffer(GL_ARRAY_BUFFER, colorVBO);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, null);
        glEnableVertexAttribArray(1);

        // Bind the IBO
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);

        // Enable shader and draw the shape via the IBO.
        BASIC_SHADER.use();
        BASIC_SHADER.setUniform(mvpMatrix, camera.mvp*model);
        BASIC_SHADER.setUniform(color, 1.0, 1.0, 1.0, 1.0);
        glDrawElements(GL_TRIANGLES, cast(int)cubeIndices.length, GL_UNSIGNED_INT, null);

        // Make sure we clean up the attribute array.
        // Avoids weird rendering glitches.
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
    }
}