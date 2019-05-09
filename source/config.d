module config;
import asdf;
static import io = std.stdio;
import std.file;

struct Config {
    float[3] backgroundColor = [.5f, .5f, .5f];
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