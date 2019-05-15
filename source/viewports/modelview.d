/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module viewports.modelview;
import assets;
import bindbc.opengl;
import components.glviewport;
import config;
import gdk.GLContext;
import gdk.Keysyms;
import gl.camera;
import gl.shader;
import gtk.ApplicationWindow;
import gtk.GLArea;
import math;
import scene.scene;

/++
    The basic viewport used in modeling view
+/
class ModelingViewport : EditorViewport
{
public:

    /// Camera move flag
    bool isMovingCamera;

    /// Camera rotate flag
    bool isRotatingCamera;

    /// The position the cursor was at when a drag began
    Vector2 referencePosition;

    /// The rotation the camera had when a drag began
    Quaternion referenceRotation;

    Camera camera;
    import std.stdio : writeln;

    this(ApplicationWindow window)
    {
        super(window);
        this.setSizeRequest(1024, 768);
    }

    override void init()
    {
        BASIC_SHADER = loadShaderOptimal!("basic");
        LINE_SHADER = loadShaderOptimal!("line");

        /// When the scene refocuses, update the camera focal point
        SCENE.addRefocusCallback(() {
            if (CONFIG.camera.autoFocus) {
                if (camera is null) return;
                if (SCENE is null) return;
                SCENE.setCameraFocalPoint(camera);
            }
        });

        camera = new Camera(this);
        camera.changeFocus(Vector3(0, 0, 0), 50);
        camera.rotation = Quaternion.axis_rotation(cradians!30, Vector3(1, 0,
                0)) * Quaternion.axis_rotation(cradians!25, Vector3(0, 1, 0));

        SCENE = new Scene(true);
        // Refocus the scene on the first child (which is a cube)
        // We do this so that the program doesn't get confused about what to focus on in the transform widget.
        SCENE.changeFocus(SCENE.rootNode.children[0]);
    }

    override bool onKeyPressEvent(GdkEventKey* key)
    {

        // Quickswitch ortho/projection
        if (key.keyval == Keysyms.GDK_Q)
        {
            if (CONFIG.camera.perspective)
            {
                this.projectionSwitch.ortho.setActive(true);
            }
            else
            {
                this.projectionSwitch.persp.setActive(true);
            }
        }

        // Activate/deactivate zen mode
        if (key.keyval == Keysyms.GDK_F12)
        {
            CONFIG.ui.window.fullscreen = !CONFIG.ui.window.fullscreen;
            if (CONFIG.ui.window.fullscreen)
            {
                window.fullscreen();
            }
            else
            {
                window.unfullscreen();
            }
        }
        return false;
    }

    override bool onButtonPressEvent(GdkEventButton* button)
    {
        if (!isRotatingCamera && button.button == 2)
        {
            if ((button.state & GdkModifierType.SHIFT_MASK) == GdkModifierType.SHIFT_MASK)
            {
                isMovingCamera = true;
                referenceRotation = camera.rotation.inverse;
            }
            else
            {
                isRotatingCamera = true;
                referenceRotation = camera.rotation;
            }
            referencePosition = Vector2(button.x, button.y);
            return true;
        }
        return false;
    }

    override bool onScrollEvent(GdkEventScroll* scroll)
    {
        camera.distance += scroll.deltaY;
        return false;
    }

    override bool onButtonReleaseEvent(GdkEventButton* button)
    {
        if (button.button == 2)
        {
            isMovingCamera = false;
            isRotatingCamera = false;
        }
        return false;
    }

    override bool onMotionNotifyEvent(GdkEventMotion* motion)
    {
        const Vector2 pos = Vector2(motion.x, motion.y);
        if (isRotatingCamera)
        {
            const Vector2 delta =   (pos - referencePosition) 
                                    * (1.0f / CONFIG.camera.rotationSlowness);

            // locally rotate vertical (pitch), globally rotate horizontal (yaw)
            camera.rotation =   Quaternion.axis_rotation(delta.y, Vector3(1, 0, 0)) 
                                * referenceRotation 
                                * Quaternion.axis_rotation(delta.x, Vector3(0, 1, 0));
            return true;
        }
        else if (isMovingCamera)
        {
            const Vector2 delta =   (pos - referencePosition) 
                                    * (camera.distance / CONFIG.camera.movementSlowness);
            referencePosition = pos;
            camera.offset(-(referenceRotation * Vector3(delta.x, -delta.y, 0)), CONFIG.camera.smooth);
        }
        return false;
    }

    override void update(double deltaTime)
    {
        camera.transformView();
        camera.update(deltaTime);
    }

    override bool draw(GLContext context, GLArea area)
    {
        if (SCENE !is null)
        {
            if (SCENE.sceneReloaded())
            {
                SCENE.setContext(this.viewport);
                nodeTree.updateTree();
            }
            SCENE.update();
            SCENE.render(camera);
        }
        return true;
    }
}

ShaderProgram loadShaderOptimal(string name)()
{
    version (RELEASE)
    {
        return ShaderProgram.fromFilesCompileTime!(name ~ ".vert", name ~ ".frag")();
    }
    else
    {
        Shader vert = Shader.loadFromFile("shaders/" ~ name ~ ".vert");
        Shader frag = Shader.loadFromFile("shaders/" ~ name ~ ".frag");
        return ShaderProgram(vert, frag);
    }
}
