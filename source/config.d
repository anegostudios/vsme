/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module config;
import asdf;
static import io = std.stdio;
import std.file;

enum VSME_TITLE = "Vintage Studio";

struct CameraConfig {
    bool perspective = true;
    float fov = 90f;
    float znear = 0.1;
    float zfar = 1000;

    bool invertX = false;
    bool invertY = false;

    float cameraRotationSlowness = 400f;
    float cameraMovementSlowness = 800f;
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