/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module gl.shader;
import bindbc.opengl;
import std.file;
import std.string : toStringz;
import std.stdio : writefln;
import std.path : extension;
import std.conv;
import gl;
import math;

/// The types of shaders supported.
enum ShaderType {
    Vertex = GL_VERTEX_SHADER,
    Fragment = GL_FRAGMENT_SHADER
}

/++
    Shader is a lightweight wrapper for OpenGL Shaders.
    See ShaderType for the currently supported shaders.
+/
struct Shader {
private:
    GLuint shaderId;
    string source;
    string sourcePath;
    ShaderType type;
public:
    
    ShaderType getType() {
        return type;
    }

    ~this() {
        glDeleteShader(shaderId);
    }

    this(string path, string code, ShaderType type) {
        this.source = code;
        this.sourcePath = path;
        this.type = type;
        writefln("Compiling shader %s...", path);

        shaderId = glCreateShader(type);

        /// Convert D string of source to something OpenGL will accept (const char*)
        const(char)* tmpString = cast(const(char)*)toStringz(source);

        /// Set shader and compile
        glShaderSource(shaderId, 1, &tmpString, GL_NULL);
        glCompileShader(shaderId);

        /// Throw an exception if any error occurs.
        GLint logLength;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            char[] errMsg = new char[](logLength+1);
            glGetShaderInfoLog(shaderId, logLength, null, errMsg.ptr);
            throw new Exception((errMsg.ptr).text);
        }
    }

    /++
        Loads a GLSL shader from file, with the following valid file extensions:
        
        ### Vertex Shaders
            * .glslv
            * .vsh
            * .vert
        
        ### Fragment Shaders
            * .glslf
            * .fsh
            * .frag
    +/
    static Shader loadFromFile(string file) {
        string code = readText(file);
        immutable(string) ext = file.extension;
        switch(ext) {
            case ".glslv":
            case ".vsh":
            case ".vert":
                return Shader(file, code, ShaderType.Vertex);

            case ".glslf":
            case ".fsh":
            case ".frag":
                return Shader(file, code, ShaderType.Fragment);

            default:
                throw new Exception("Unknown shader extension! (supported: .glslv, .vsh, .vert, .glslf, .fsh & .frag)");
        }
    }
}

struct ShaderProgram {
private:
    GLuint programId;
    Shader vertex;
    Shader fragment;

public:
    ~this() {
        /// Clean up this shader program on destruction.
        glDetachShader(programId, this.vertex.shaderId);
        glDetachShader(programId, this.fragment.shaderId);
        glDeleteProgram(programId);
    }

    this(Shader vertex, Shader fragment) {
        // Lil' type checking
        if (vertex.type != ShaderType.Vertex) 
            throw new Exception("Cannot link vertex shader as a fragment shader!");

        if (fragment.type != ShaderType.Fragment) 
            throw new Exception("Cannot link fragment shader as a vertex shader!");

        writefln("Linking %s and %s...", vertex.sourcePath, fragment.sourcePath);

        /// Create program and attach shaders
        programId = glCreateProgram();
        glAttachShader(programId, vertex.shaderId);
        glAttachShader(programId, fragment.shaderId);
        glLinkProgram(programId);

        /// throw an Exception if it failed linking.
        GLint logLength;
        glGetShaderiv(programId, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            char[] errMsg = new char[](logLength+1);
            glGetProgramInfoLog(programId, logLength, null, errMsg.ptr);
            throw new Exception((errMsg.ptr).text);
        }

        /// Set these, so we can refer back to them in the future if needed.
        this.vertex = vertex;
        this.fragment = fragment;
    }

    /// Creates shader from file at compile time (shader will be baked in to executable.)
    static fromFilesCompileTime(string vert, string frag)() {
        Shader vertShader = Shader(vert, import(vert), ShaderType.Vertex);
        Shader fragShader = Shader(frag, import(frag), ShaderType.Fragment);
        return ShaderProgram(vertShader, fragShader);
    }

    /// Get OpenGL ID of a shader uniform.
    GLuint getUniform(string name) {
        return glGetUniformLocation(programId, toStringz(name));
    }

    /// Set float uniform.
    void setUniform(GLuint id, float x) {
        glUniform1f(id, x);
    }

    /// Set 2D uniform vector.
    void setUniform(GLuint id, float x, float y) {
        glUniform2f(id, x, y);
    }

    /// Set 3D uniform vector.
    void setUniform(GLuint id, float x, float y, float z) {
        glUniform3f(id, x, y, z);
    }

    /// Set 4D uniform vector.
    void setUniform(GLuint id, float x, float y, float z, float w) {
        glUniform4f(id, x, y, z, w);
    }

    /// Set Matrix4x4 uniform.
    void setUniform(GLuint id, Matrix4x4 matrix) {
        glUniformMatrix4fv(id, 1, GL_TRUE, &matrix.matrix[0][0]);
    }

    /// Set 4D uniform vector.
    void setUniform(GLuint id, Vector4 vec) {
        setUniform(id, vec.x, vec.y, vec.z, vec.w);
    }

    /// Set 3D uniform vector.
    void setUniform(GLuint id, Vector3 vec) {
        setUniform(id, vec.x, vec.y, vec.z);
    }

    /// Set 2D uniform vector.
    void setUniform(GLuint id, Vector2 vec) {
        setUniform(id, vec.x, vec.y);
    }

    void use() {
        glUseProgram(programId);
    }
}