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
import gtk.Popover;
import gtk.TreeView;
import gtk.Button;
import gtk.ToggleButton;
import gtk.Image;
import gtk.TreeStore;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.CellRendererText;
import gtk.CellRendererToggle;
import gtk.CellRendererPixbuf;
import gtk.CellRenderer;
import gtk.TreeViewColumn;
import scene.node;
import scene.scene;
import std.conv;
import gobject.Value;

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
        this.setMarginStart(8);
        this.setMarginTop(8);

        persp.setActive(CONFIG.camera.perspective);
        ortho.setActive(!CONFIG.camera.perspective);

        persp.getStyleContext().addClass("vsme-mode-switch");
        ortho.getStyleContext().addClass("vsme-mode-switch");

        persp.getStyleContext().invalidate();
        ortho.getStyleContext().invalidate();

        this.showAll();
    }
}

enum EditorTreeIndexes : uint {
    NameColumn = 0,
    VisibleColumn = 1,
    MapId = 2
}

class EditorNodeTree : Popover {
private:
    TreeStore treeStore;
    CellRendererText nameRenderer;
    CellRendererToggle visibleRenderer;
    TreeViewColumn visibleColumn;
    Node[] nodeMapping;

    TreeIter pathToIter(string path) {
        TreeIter iter = new TreeIter();
        treeStore.getIter(iter, new TreePath(path));
        return iter;
    }

    int getIndexOfIter(TreeIter iter) {
        return treeStore.getValueInt(iter, EditorTreeIndexes.MapId);
    }

    int getIndexOfPath(string path) {
        return getIndexOfIter(pathToIter(path));
    }

public:
    TreeView nodeTree;

    this(Widget parent) {
        super(parent);

        nodeTree = new TreeView();
        treeStore = new TreeStore([GType.STRING, GType.BOOLEAN, GType.INT]);

        nameRenderer = new CellRendererText();
        nameRenderer.addOnEdited((path, text, widget) {
            TreeIter iter = pathToIter(path);
            int id = getIndexOfIter(iter);
            this.setName(iter, id, text);
        });
        nameRenderer.setProperty("editable", true);
        nodeTree.appendColumn(new TreeViewColumn("Name", nameRenderer, "text", EditorTreeIndexes.NameColumn));


        visibleRenderer = new CellRendererToggle();
        visibleRenderer.setProperty("radio", false);
        visibleRenderer.setProperty("activatable", true);

        visibleRenderer.addOnToggled((path, widget) {
            TreeIter iter = pathToIter(path);
            int id = getIndexOfIter(iter);
            if (CONFIG.ui.elementList.propergateDisable) {
                propergateVisibility(iter, !nodeMapping[id].visible);
            } else {
                setVisibility(iter, id, !nodeMapping[id].visible);
            }
        });

        visibleColumn = new TreeViewColumn("Visible", visibleRenderer, "active", EditorTreeIndexes.VisibleColumn);
        nodeTree.appendColumn(visibleColumn);

        if (CONFIG.debugMode) nodeTree.appendColumn(new TreeViewColumn("IDs", nameRenderer, "text", EditorTreeIndexes.MapId));

        nodeTree.setModel(treeStore);
        nodeTree.setReorderable(true);

        this.addOnShow((widget) {
            nodeTree.showAll();
        });

        this.setModal(false);
        this.setPosition(GtkPositionType.BOTTOM);
        this.setConstrainTo(GtkPopoverConstraint.WINDOW);
        this.add(nodeTree);
    }

    void propergateVisibility(TreeIter iter, bool visibility) {
        if (treeStore.iterHasChild(iter)) {
            TreeIter child;
            if (child.getType() != GType.INVALID) {
                treeStore.iterChildren(child, iter);
                do {
                    propergateVisibility(child, visibility);
                } while (treeStore.iterNext(child) != false);
            }
        }

        int id = getIndexOfIter(iter);
        setVisibility(iter, id, visibility);
    }

    void setVisibility(TreeIter iter, int id, bool visibility) {
        nodeMapping[id].visible = visibility;
        treeStore.setValue(iter, EditorTreeIndexes.VisibleColumn, new Value(nodeMapping[id].visible));
    }

    void setName(TreeIter iter, int id, string newName) {
        nodeMapping[id].name = newName;
        treeStore.setValue(iter, EditorTreeIndexes.NameColumn, new Value(newName));
    }

    string getName(TreeIter iter, int id) {
        return treeStore.getValueString(iter, id);
    }

    void updateTree() {
        if (SCENE is null) return;
        nodeMapping = [];

        treeStore.clear();
        TreeIter treeIterator = treeStore.createIter();
        updateTreeAppend(SCENE.rootNode, treeIterator);
        nodeTree.expandAll();
    }

    void updateTreeAppend(Node node, TreeIter iterator) {
        treeStore.setValuesv(iterator, [EditorTreeIndexes.NameColumn, EditorTreeIndexes.VisibleColumn, EditorTreeIndexes.MapId], [new Value(node.name), new Value(node.visible), new Value(nodeMapping.length)]);
        nodeMapping ~= node;
        foreach(child; node.children) {
            TreeIter iter = treeStore.createIter(iterator);
            updateTreeAppend(child, iter);
        }
    }
}

class EditorViewport : Overlay {
protected:
    GLArea viewport;
    EventBox evbox;
    EditorProjSwitch projectionSwitch;

    // Node Tree
    ToggleButton nodeTreeToggle;
    EditorNodeTree nodeTree;

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
        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_POINT_SMOOTH);
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