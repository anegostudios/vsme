/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
import gtk.ScrolledWindow;
import gtk.SpinButton;
import gtk.VBox;
import gtk.HBox;
import gtk.Label;
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
    VBox controlBox;

    ScrolledWindow scrollbar;

    TreeStore treeStore;
    CellRendererText nameRenderer;
    TreeViewColumn nameColumn;
    CellRendererToggle visibleRenderer;
    TreeViewColumn visibleColumn;
    Node[] nodeMapping;

    TreeIter pathToIter(string path) {
        TreeIter iter = new TreeIter();
        treeStore.getIter(iter, new TreePath(path));
        return iter;
    }

    TreeIter pathToIter(TreePath path) {
        TreeIter iter = new TreeIter();
        treeStore.getIter(iter, path);
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
    Button addNewObjectButton;
    Button deleteSelectedObjectButton;

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
        nameColumn = new TreeViewColumn("Name", nameRenderer, "text", EditorTreeIndexes.NameColumn);
        nameColumn.setExpand(true);
        nodeTree.appendColumn(nameColumn);


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

        visibleColumn = new TreeViewColumn("👁️", visibleRenderer, "active", EditorTreeIndexes.VisibleColumn);
        visibleColumn.setAlignment(0.5f);
        nodeTree.appendColumn(visibleColumn);

        if (CONFIG.debugMode) nodeTree.appendColumn(new TreeViewColumn("IDs", nameRenderer, "text", EditorTreeIndexes.MapId));

        nodeTree.setModel(treeStore);
        nodeTree.setReorderable(true);

        nodeTree.setActivateOnSingleClick(true);
        nodeTree.addOnRowActivated((path, collumn, view) {
            int id = getIndexOfIter(pathToIter(path));
            SCENE.changeFocus(nodeMapping[id]);
        });

        this.addOnShow((widget) {
            controlBox.showAll();
        });

        this.setModal(false);
        this.setPosition(GtkPositionType.BOTTOM);
        this.setConstrainTo(GtkPopoverConstraint.WINDOW);

        scrollbar = new ScrolledWindow();
        scrollbar.setSizeRequest(256, 512);
        scrollbar.add(nodeTree);


        addNewObjectButton = new Button();
        Image addNewObjectButtonImg = new Image("list-add-symbolic", IconSize.MENU);
        addNewObjectButton.add(addNewObjectButtonImg);
        addNewObjectButton.addOnClicked((widget) {
            if (selectedItem() is null) {
                auto elm = SCENE.addNewElement("Cube", SCENE.rootNode);
                elm.init();
                SCENE.rootNode.children ~= elm;

                SCENE.changeFocus(elm);
                updateTree(elm);
                return;
            }
            int id = getIndexOfIter(selectedItem());
            auto elm = SCENE.addNewElement("Cube", nodeMapping[id]);
            elm.init();
            nodeMapping[id].children ~= elm;

            SCENE.changeFocus(elm);
            updateTree(elm);
        });

        deleteSelectedObjectButton = new Button();
        Image deleteSelectedObjectButtonImg = new Image("list-remove-symbolic", IconSize.MENU);
        deleteSelectedObjectButton.add(deleteSelectedObjectButtonImg);
        deleteSelectedObjectButton.getStyleContext().addClass("destructive-action");
        deleteSelectedObjectButton.addOnClicked((widget) {
            if (selectedItem() is null) return;

            int id = getIndexOfIter(selectedItem());
            Node parent = nodeMapping[id].parent;
            
            nodeMapping[id].selfDestruct();

            SCENE.changeFocus(parent);
            updateTree(parent);
        });

        HBox hb = new HBox(false, 4);

        StackSwitcher sw = new StackSwitcher();
        sw.packStart(addNewObjectButton, true, true, 0);
        sw.packEnd(deleteSelectedObjectButton, true, true, 0);

        hb.packStart(sw, false, false, 2);

        controlBox = new VBox(false, 2);
        controlBox.packStart(scrollbar, true, true, 0);
        controlBox.packStart(hb, false, false, 0);
        controlBox.setSizeRequest(256, 512+32);

        this.add(controlBox);
    }

    TreeIter selectedItem() {
        return nodeTree.getSelectedIter();
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

    private TreeIter toFocusTree;
    void updateTree(Node focused = null) {
        if (SCENE is null) return;
        nodeMapping = [];
        toFocusTree = null;

        treeStore.clear();
        TreeIter treeIterator = treeStore.createIter();
        if (SCENE.rootNode.children.length == 0) return;
        updateTreeAppend(SCENE.rootNode.children[0], treeIterator, focused);
        nodeTree.expandAll();

        if (toFocusTree !is null) {
            nodeTree.getSelection().selectIter(toFocusTree);
        } else {
            nodeTree.getSelection().selectIter(treeIterator);
        }
    }

    void updateTreeAppend(Node node, TreeIter iterator, Node focused = null) {
        treeStore.setValuesv(iterator, [EditorTreeIndexes.NameColumn, EditorTreeIndexes.VisibleColumn, EditorTreeIndexes.MapId], [new Value(node.name), new Value(node.visible), new Value(nodeMapping.length)]);
        if (focused is node) {
            toFocusTree = iterator;
        }
        nodeMapping ~= node;
        
        foreach(child; node.children) {
            TreeIter iter = treeStore.createIter(iterator);
            updateTreeAppend(child, iter, focused);
        }
    }
}

class VectorCollection : HBox {
private:
    alias valueChangedCallbackType = void delegate(Vector3);

    valueChangedCallbackType[] callbacks;

    SpinButton xButton;
    SpinButton yButton;
    SpinButton zButton;

    void handleValueChange(SpinButton widget) {
        double x = xButton.getValue();
        double y = yButton.getValue();
        double z = zButton.getValue();
        foreach (callback; callbacks) {
            callback(Vector3(x, y, z));
        }
    }

public:
    this(int spacing) {
        super(false, spacing);
        xButton = new SpinButton(int.min, int.max, 0.1);
        xButton.getStyleContext().addClass("spin-x");

        yButton = new SpinButton(int.min, int.max, 0.1);
        yButton.getStyleContext().addClass("spin-y");

        zButton = new SpinButton(int.min, int.max, 0.1);
        zButton.getStyleContext().addClass("spin-z");

        xButton.setSnapToTicks(false);
        yButton.setSnapToTicks(false);
        zButton.setSnapToTicks(false);

        xButton.setValue(0);
        yButton.setValue(0);
        zButton.setValue(0);

        xButton.setDigits(2);
        yButton.setDigits(2);
        zButton.setDigits(2);

        xButton.setWidthChars(4);
        yButton.setWidthChars(4);
        zButton.setWidthChars(4);

        xButton.addOnValueChanged(&handleValueChange);
        yButton.addOnValueChanged(&handleValueChange);
        zButton.addOnValueChanged(&handleValueChange);

        // TODO: implement so that modifying text always updates.
        // import cairo.Context : Context;
        // xButton.addOnDraw((Context ctx, Widget widget) { handleValueChange(xButton); return false; });
        // yButton.addOnDraw((Context ctx, Widget widget) { handleValueChange(yButton); return false; });
        // zButton.addOnDraw((Context ctx, Widget widget) { handleValueChange(zButton); return false; });

        this.packStart(xButton, false, false, 4);
        this.packStart(yButton, false, false, 4);
        this.packStart(zButton, false, false, 4);

        this.showAll();
    }

    void updateStyleContext() {
        xButton.getStyleContext().removeClass("spin-x");
        yButton.getStyleContext().removeClass("spin-y");
        zButton.getStyleContext().removeClass("spin-z");
        xButton.getStyleContext().removeClass("spin-x-dark");
        yButton.getStyleContext().removeClass("spin-y-dark");
        zButton.getStyleContext().removeClass("spin-z-dark");

        if (CONFIG.darkMode) {
            xButton.getStyleContext().addClass("spin-x-dark");
            yButton.getStyleContext().addClass("spin-y-dark");
            zButton.getStyleContext().addClass("spin-z-dark");
        } else {
            xButton.getStyleContext().addClass("spin-x");
            yButton.getStyleContext().addClass("spin-y");
            zButton.getStyleContext().addClass("spin-z");
        }
    }

    void addOnValueChanged(void delegate(Vector3) cb) {
        callbacks ~= cb;
    }

    Vector3 getValue() {
        return Vector3(xButton.getValue(), yButton.getValue(), zButton.getValue());
    }

    void setValue(Vector3 value) {
        xButton.setValue(value.x);
        yButton.setValue(value.y);
        zButton.setValue(value.z);
    }
}

class ContextualPopover : Popover {
private:
    VBox container;
    Widget parent;
    Widget dockedTo;

    bool isRefocusing = false;

    void refocus() {
        isRefocusing = true;
        if (SCENE is null || SCENE.focus is null) return;
        position.setValue(SCENE.focus.startPosition);
        size.setValue(SCENE.focus.endPosition-SCENE.focus.startPosition);
        rotation.setValue(SCENE.focus.rotation);
        origin.setValue(SCENE.focus.origin);
        isRefocusing = false;
    }

public:
    VectorCollection position;
    VectorCollection size;
    VectorCollection rotation;
    VectorCollection origin;

    void dock(Widget dockedTo) {
        this.dockedTo = dockedTo;
        this.setRelativeTo(dockedTo);
        this.setModal(false);
    }

    void unDock() {
        this.dockedTo = null;
        this.setModal(true);
        this.setRelativeTo(parent);
    }

    bool docked() {
        return (dockedTo !is null);
    }

    this(Widget parent) {
        super(parent);
        this.parent = parent;

        position = new VectorCollection(4);
        size = new VectorCollection(4);
        rotation = new VectorCollection(4);
        origin = new VectorCollection(4);

        position.addOnValueChanged((position) {
            if (isRefocusing) return;
            SCENE.focus.startPosition = position;
            SCENE.focus.endPosition = position+size.getValue();
            SCENE.changeFocus(SCENE.focus);
        });

        size.addOnValueChanged((size) {
            if (isRefocusing) return;
            SCENE.focus.endPosition = SCENE.focus.startPosition+size;
            SCENE.changeFocus(SCENE.focus);
        });

        rotation.addOnValueChanged((rotation) {
            if (isRefocusing) return;
            SCENE.focus.rotation = rotation;
            SCENE.changeFocus(SCENE.focus);
        });

        origin.addOnValueChanged((origin) {
            if (isRefocusing) return;
            SCENE.focus.origin = origin;
        });

        container = new VBox(false, 4);
        container.packStart(new Label("Translation"), false, true, 4);
        container.packStart(position, false, false, 4);

        container.packStart(new Label("Scale"), false, true, 4);
        container.packStart(size, false, false, 4);

        container.packStart(new Label("Rotation"), false, true, 4);
        container.packStart(rotation, false, false, 4);

        container.packStart(new Label("Rotation Origin"), false, true, 4);
        container.packStart(origin, false, false, 4);

        SCENE.addRefocusCallback(&refocus);

        this.addOnShow((widget) {
            //refocus();
            this.showAll();
        });

        this.setConstrainTo(GtkPopoverConstraint.WINDOW);
        this.add(container);
    }

    void popUp(Vector2 position) {
        this.position.updateStyleContext();
        this.size.updateStyleContext();
        this.origin.updateStyleContext();
        this.rotation.updateStyleContext();
        this.setPosition(GtkPositionType.TOP);
        if (dockedTo !is null) {
            this.setPointingTo(new GdkRectangle(0, 0, 32, 32));
            this.showAll();
            return;
        }
        this.setPointingTo(new GdkRectangle(cast(int)position.x, cast(int)position.y, 2, 2));
        this.popup();
    }

    void popDown() {
        if (dockedTo !is null) hide();
        else popdown();
        unDock();
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
    ApplicationWindow window;

    ContextualPopover contextPopover;
    ToggleButton contextToggle;

public:
    ref GLArea getViewport() {
        return viewport;
    }
    int width;
    int height;

    this(ApplicationWindow root) {
        this.window = root;
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

        this.addOverlay(contextToggle);


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