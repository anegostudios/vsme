module config;
import asdf;
static import io = std.stdio;
import std.file;

struct CameraConfig {
    bool perspective = true;
    float fov = 90f;
    float znear = 0.1;
    float zfar = 1000;
}

struct Config {
    float[3] backgroundColor = [.5f, .5f, .5f];
    bool darkMode = true;
    CameraConfig camera;
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