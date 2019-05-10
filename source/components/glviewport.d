module components.glviewport;
import gtk.GLArea;
import gtk.EventBox;
import bindbc.opengl;
import gdk.GLContext : GLContext;
import gtk.ApplicationWindow;
import config;

public:

class EditorViewport : EventBox {
protected:
    GLArea viewport;

public:
    ref GLArea getViewport() {
        return viewport;
    }

    this() {
        viewport = new GLArea();
        viewport.addOnRealize((widget) {
            viewport.setDoubleBuffered(true);
            viewport.setHasDepthBuffer(true);
            viewport.setHasStencilBuffer(true);

            viewport.makeCurrent();
            initGL();
            init();
        });
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
        viewport.addOnResize((width, height, area) {
            glViewport(0, 0, width, height);
        });

        // Present it
        viewport.addOnRender((context, area) {
            glClearColor(CONFIG.backgroundColor[0], CONFIG.backgroundColor[1], CONFIG.backgroundColor[2], 1f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            return draw(context, area);
        });
    }

    abstract void init();

    abstract bool draw(GLContext context, GLArea area);
}

/// Unload OpenGL on application quit.
static ~this() {
    unloadOpenGL();
}