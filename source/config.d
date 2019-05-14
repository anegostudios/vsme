module config;
import asdf;
static import io = std.stdio;
import std.file;

struct CameraConfig {
    bool perspective = true;
    float fov = 90f;
    float znear = 0.1;
    float zfar = 1000;

    bool invertX = false;
    bool invertY = false;

    float cameraSlowFactor = 4f;
}

struct ElementListConfig {
    bool propergateDisable = true;
}

struct WindowConfig {
    int width;
    int height;
    bool maximized;
    bool fullscreen;
}

struct UIConfig {
    ElementListConfig elementList;
    WindowConfig window;
}

struct RenderConfig {
    bool showHelperGrid = true;
    bool showBlockHeightHelper = false;
    bool showRotationCenter = false;
}

struct Config {
    float[3] backgroundColor = [0.125f, 0.141f, 0.149f];
    bool darkMode = true;
    bool debugMode = false;
    CameraConfig camera;
    UIConfig ui;
    RenderConfig render;
}

__gshared static Config CONFIG;

void saveConfiguration() {
    io.writeln("Saving configuration...");
    write("config.json", serializeToJsonPretty(CONFIG));
}

shared static this() {
    io.writeln("Loading configuration...");
    if (exists("config.json")) {
        CONFIG = deserialize!Config(readText("config.json"));
    }
}