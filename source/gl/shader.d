module gl.shader;
import bindbc.opengl;
import std.file;
import std.string : toStringz;
import std.stdio : writefln;
import std.path : extension;
import std.conv;
import gl;

enum ShaderType {
    Vertex = GL_VERTEX_SHADER,
    Fragment = GL_FRAGMENT_SHADER
}

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
        writefln("Compiling shader %s...", path);
        this.source = code;
        this.sourcePath = path;
        this.type = type;

        shaderId = glCreateShader(type);

        const(char)* tmpString = cast(const(char)*)toStringz(source);

        glShaderSource(shaderId, 1, &tmpString, GL_NULL);
        glCompileShader(shaderId);

        GLint logLength;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            char[] errMsg = new char[](logLength+1);
            glGetShaderInfoLog(shaderId, logLength, null, errMsg.ptr);
            throw new Exception((errMsg.ptr).text);
        }
    }

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
        glDetachShader(programId, this.vertex.shaderId);
        glDetachShader(programId, this.fragment.shaderId);
    }

    this(Shader vertex, Shader fragment) {
        // Lil' type checking
        if (vertex.type != ShaderType.Vertex) 
            throw new Exception("Cannot link vertex shader as a fragment shader!");
            
        if (fragment.type != ShaderType.Fragment) 
            throw new Exception("Cannot link fragment shader as a vertex shader!");

        writefln("Linking %s and %s...", vertex.sourcePath, fragment.sourcePath);

        programId = glCreateProgram();

        glAttachShader(programId, vertex.shaderId);
        glAttachShader(programId, fragment.shaderId);
        glLinkProgram(programId);

        GLint logLength;
        glGetShaderiv(programId, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            char[] errMsg = new char[](logLength+1);
            glGetProgramInfoLog(programId, logLength, null, errMsg.ptr);
            throw new Exception((errMsg.ptr).text);
        }

        this.vertex = vertex;
        this.fragment = fragment;
    }

    /// Creates shader from file at compile time (shader will be baked in to executable.)
    static fromFilesCompileTime(string vert, string frag)() {
        Shader vertShader = Shader(vert, import(vert), ShaderType.Vertex);
        Shader fragShader = Shader(frag, import(frag), ShaderType.Fragment);
        return ShaderProgram(vertShader, fragShader);
    }

    void use() {
        glUseProgram(programId);
    }
}