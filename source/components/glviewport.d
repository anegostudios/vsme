module components.glviewport;
import gtk.GLArea;
import gtk.EventBox;
import bindbc.opengl;
import gdk.GLContext : GLContext;
import gtk.ApplicationWindow;
import config;
import std.stdio;
import gtk.Widget;
import gobject.Signals;

public:

class EditorViewport : EventBox {
protected:
    GLArea viewport;

public:
    ref GLArea getViewport() {
        return viewport;
    }
    int width;
    int height;

    this(ApplicationWindow root) {
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

        this.addEvents(GdkEventMask.ALL_EVENTS_MASK);

        /// TODO: the logic should probably be moved elsewhere.
        root.addOnKeyPress((GdkEventKey* key, widget) => onKeyPressEvent(key));
        root.addOnKeyRelease((GdkEventKey* key, widget) => onKeyReleaseEvent(key));

        this.addOnButtonPress((GdkEventButton* button, widget) => onButtonPressEvent(button));
        this.addOnButtonRelease((GdkEventButton* button, widget) => onButtonReleaseEvent(button));
        
        this.addOnMotionNotify((GdkEventMotion* motion, widget) => onMotionNotifyEvent(motion));

        this.add(viewport);
        this.showAll();
    }

    final void initGL() {
        /// Load OpenGL
        auto support = loadOpenGL();
        if (support < GLSupport.gl32) {
            throw new Error("Expected AT LEAST OpenGL 3.2 support!");
        }

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