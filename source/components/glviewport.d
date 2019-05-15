/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module components.glviewport;
import bindbc.opengl;
import components.editor;
import config;
import core.time;
import gdk.GLContext : GLContext;
import gtk.ApplicationWindow;
import gtk.EventBox;
import gtk.GLArea;
import gtk.Image;
import gtk.Overlay;
import gtk.ToggleButton;
import math;
import std.stdio;

/// Alias to course MonoTime.
alias FastMonoTime = MonoTimeImpl!(ClockType.coarse);

class EditorViewport : Overlay {
private:
    void onResize(int width, int height, GLArea area) {
        glViewport(0, 0, width, height);
        this.width = width;
        this.height = height;
    }

protected:
    GLArea viewport;
    EventBox evbox;
    EditorProjSwitch projectionSwitch;

    // Node Tree
    ToggleButton nodeTreeToggle;
    EditorNodeTree nodeTree;
    ApplicationWindow window;

    ContextualPopover contextPopover;
    ToggleButton contextToggle;

public:
    ref GLArea getViewport() {
        return viewport;
    }
    /// Width of viewport
    int width;

    /// Height of viewport.
    int height;

    this(ApplicationWindow root) {
        this.window = root;
        
        evbox = new EventBox();
        viewport = new GLArea();

        viewport.addOnRealize((widget) {

            this.width = widget.getAllocatedWidth();
            this.height = widget.getAllocatedHeight();
            writefln("Allocated %dx%d of space...", this.width, this.height);

            // Enable double buffering, depth buffering and stencil buffering (for good measure.)
            viewport.setDoubleBuffered(true);
            viewport.setHasDepthBuffer(true);
            viewport.setHasStencilBuffer(true);

            // Initialize OpenGL context, then run user initialization logic.
            viewport.makeCurrent();
            initGL();
            init();
            
            // This sets up the draw routine to draw repeatedly as fast as GTK allows.
            viewport.addTickCallback((widget, fclock) {
                widget.queueDraw();
                return true;
            });
        });
        evbox.add(viewport);

        // Set up events.
        root.addOnKeyPress((GdkEventKey* key, widget) => onKeyPressEvent(key));
        root.addOnKeyRelease((GdkEventKey* key, widget) => onKeyReleaseEvent(key));
        evbox.addOnButtonRelease((GdkEventButton* button, widget) => onButtonReleaseEvent(button));
        root.addOnScroll((GdkEventScroll* scroll, widget) => onScrollEvent(scroll));
        root.addOnMotionNotify((GdkEventMotion* motion, widget) => onMotionNotifyEvent(motion));
        this.add(evbox);

        /// Add projection switch overlay (top left corner)
        projectionSwitch = new EditorProjSwitch(this);
        this.addOverlay(projectionSwitch);

        /// Add node tree overlay (top right corner)
        nodeTreeToggle = new ToggleButton();
        nodeTreeToggle.setHalign(Align.END);
        nodeTreeToggle.setValign(Align.START);
        nodeTreeToggle.setMarginEnd(8);
        nodeTreeToggle.setMarginTop(8);
        Image nodeTreeToggleImg = new Image("open-menu-symbolic", IconSize.MENU);
        nodeTreeToggle.add(nodeTreeToggleImg);
        nodeTreeToggle.getStyleContext().addClass("suggested-action");

        nodeTree = new EditorNodeTree(nodeTreeToggle);
        nodeTreeToggle.addOnClicked((widget) {
            if (nodeTreeToggle.getActive()) {
                nodeTree.popup();
                return;
            }
            nodeTree.popdown();
        });

        this.addOverlay(nodeTreeToggle);

        /// Add contextual popover for transformation.
        contextPopover = new ContextualPopover(viewport);
        evbox.addOnButtonPress((GdkEventButton* button, widget) {
            if (button.button == 3) {
                if (!contextPopover.docked) {
                    contextPopover.popUp(Vector2(button.x, button.y));
                }
            }
            onButtonPressEvent(button);
            return false;
        });

        /// Add toggle for the contextual popover to stay constant.
        contextToggle = new ToggleButton();
        contextToggle.setHalign(Align.END);
        contextToggle.setValign(Align.END);
        contextToggle.setMarginEnd(8);
        contextToggle.setMarginBottom(8);
        Image contextToggleImg = new Image("go-up-symbolic", IconSize.MENU);
        contextToggle.add(contextToggleImg);
        contextToggle.getStyleContext().addClass("suggested-action");
        contextToggle.addOnClicked((widget) {
            if (contextToggle.getActive()) {
                contextPopover.dock(contextToggle);
                contextPopover.popUp(Vector2(0, 0));
                return;
            }
            contextPopover.popDown();
        });

        // Apply the overlay and show it.
        this.addOverlay(contextToggle);
        this.showAll();
    }

    /++
        Initializes OpenGL.
    +/
    final void initGL() {
        /// Load OpenGL
        auto support = loadOpenGL();
        if (support < GLSupport.gl32) {
            throw new Error("Expected AT LEAST OpenGL 3.2 support!");
        }

        // Enable multi-sampling
        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_POINT_SMOOTH);
        glEnable(GL_MULTISAMPLE);
        glDisable(GL_CULL_FACE);

        // Resize OpenGL viewport if neccesary
        viewport.addOnResize(&onResize);

        // Present it
        viewport.addOnRender((context, area) {
            static FastMonoTime lastTime;
            auto now = FastMonoTime.currTime();
            if (lastTime is FastMonoTime.init)
                lastTime = now;
            auto delta = (now - lastTime).total!"hnsecs" / 10_000_000.0;
            lastTime = now;

            glClearColor(CONFIG.backgroundColor[0], CONFIG.backgroundColor[1], CONFIG.backgroundColor[2], 1f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            update(delta);
            return draw(context, area);
        });
    }

    /// Custom initialization logic
    abstract void init();

    /// Custom update logic
    abstract void update(double deltaTime);

    /// Custom draw logic
    abstract bool draw(GLContext context, GLArea area);
}

/// Unload OpenGL on application quit.
static ~this() {
    unloadOpenGL();
}