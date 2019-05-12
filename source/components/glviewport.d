module components.glviewport;
import gtk.GLArea;
import gtk.EventBox;
import gtk.Overlay;
import bindbc.opengl;
import gdk.GLContext : GLContext;
import gtk.ApplicationWindow;
import config;
import std.stdio;
import gtk.Widget;
import gobject.Signals;
import gtk.ToggleButton;
import gtk.StackSwitcher;

public:

class EditorProjSwitch : StackSwitcher {
private:
    EditorViewport parent;

    bool isHandlingSwitch;

public:
    /// Orthographic switch
    ToggleButton ortho;

    /// Perspective switch
    ToggleButton persp;

    this(EditorViewport parent) {
        super();
        this.parent = parent;

        persp = new ToggleButton("Persp");
        persp.addOnClicked((widget) {
            if (isHandlingSwitch) return;

            isHandlingSwitch = true;
            ortho.setActive(false);
            persp.setActive(true);
            CONFIG.camera.perspective = true;
            isHandlingSwitch = false;
        });

        ortho = new ToggleButton("Ortho");
        ortho.addOnClicked((widget) {
            if (isHandlingSwitch) return;

            isHandlingSwitch = true;
            ortho.setActive(true);
            persp.setActive(false);
            CONFIG.camera.perspective = false;
            isHandlingSwitch = false;
        });

        this.packStart(persp, true, false, 0);
        this.packEnd(ortho, true, false, 0);

        this.setHalign(GtkAlign.START);
        this.setValign(GtkAlign.START);

        this.setSizeRequest(32, 16);
        this.setMarginStart(4);
        this.setMarginTop(4);

        persp.setActive(CONFIG.camera.perspective);
        ortho.setActive(!CONFIG.camera.perspective);

        persp.getStyleContext().addClass("vsme-mode-switch");
        ortho.getStyleContext().addClass("vsme-mode-switch");

        persp.getStyleContext().invalidate();
        ortho.getStyleContext().invalidate();

        this.showAll();
    }
}

class EditorViewport : Overlay {
protected:
    GLArea viewport;
    EventBox evbox;
    EditorProjSwitch projectionSwitch;

public:
    ref GLArea getViewport() {
        return viewport;
    }
    int width;
    int height;

    this(ApplicationWindow root) {
        evbox = new EventBox();
        viewport = new GLArea();
        viewport.addOnRealize((widget) {
            this.width = widget.getAllocatedWidth();
            this.height = widget.getAllocatedHeight();
            writefln("Allocated %dx%d of space...", this.width, this.height);

            viewport.setDoubleBuffered(true);
            viewport.setHasDepthBuffer(true);
            viewport.setHasStencilBuffer(true);

            viewport.makeCurrent();
            initGL();
            init();
            
            viewport.addTickCallback((widget, fclock) {
                widget.queueDraw();
                return true;
            });
        });
        evbox.add(viewport);

        /// TODO: the logic should probably be moved elsewhere.
        root.addOnKeyPress((GdkEventKey* key, widget) => onKeyPressEvent(key));
        root.addOnKeyRelease((GdkEventKey* key, widget) => onKeyReleaseEvent(key));

        evbox.addOnButtonPress((GdkEventButton* button, widget) => onButtonPressEvent(button));
        evbox.addOnButtonRelease((GdkEventButton* button, widget) => onButtonReleaseEvent(button));
        root.addOnScroll((GdkEventScroll* scroll, widget) => onScrollEvent(scroll));
        root.addOnMotionNotify((GdkEventMotion* motion, widget) => onMotionNotifyEvent(motion));
        this.add(evbox);

        projectionSwitch = new EditorProjSwitch(this);
        this.addOverlay(projectionSwitch);
        this.showAll();
    }

    // bool onKeyPressEvent(GdkEventKey* key);
    // bool onKeyReleaseEvent(GdkEventKey* key);

    // bool onButtonPressEvent(GdkEventButton* key);
    // bool onButtonReleaseEvent(GdkEventButton* key);

    // bool onMotionNotifyEvent(GdkEventMotion* key);

    final void initGL() {
        /// Load OpenGL
        auto support = loadOpenGL();
        if (support < GLSupport.gl32) {
            throw new Error("Expected AT LEAST OpenGL 3.2 support!");
        }

        // Enable multi-sampling
        glEnable(GL_PROGRAM_POINT_SIZE);
        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_MULTISAMPLE);
        glDisable(GL_CULL_FACE);

        // Resize OpenGL viewport if neccesary
        viewport.addOnResize(&onResize);

        // Present it
        viewport.addOnRender((context, area) {
            glClearColor(CONFIG.backgroundColor[0], CONFIG.backgroundColor[1], CONFIG.backgroundColor[2], 1f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            update();
            return draw(context, area);
        });
    }

    abstract void init();

    abstract void update();

    abstract bool draw(GLContext context, GLArea area);

    void onResize(int width, int height, GLArea area) {
        glViewport(0, 0, width, height);
        this.width = width;
        this.height = height;
    }
}

/// Unload OpenGL on application quit.
static ~this() {
    unloadOpenGL();
}