/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module components.editor.tree;
import config;
import gobject.Value;
import gtk.Button;
import gtk.CellRendererText;
import gtk.CellRendererToggle;
import gtk.HBox;
import gtk.Image;
import gtk.Popover;
import gtk.ScrolledWindow;
import gtk.StackSwitcher;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.TreeStore;
import gtk.TreeModelIF;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.VBox;
import gtk.Widget;
import gdk.DragContext;
import scene.node;
import scene.scene;

/++
    List of indices in the tree listing and their IDs
+/
enum EditorTreeIndices : uint {
    NameColumn = 0,
    VisibleColumn = 1,
    MapId = 2
}

/++
    A tree containing the nodes of the SCENE allowing the nodes to be modified etc.
+/
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
    Node lastRemoved;

    TreeIter toFocusTree;

    bool isMoving;

    TreeIter pathToIter(string path) {
        return pathToIter(treeStore, path);
    }

    TreeIter pathToIter(TreePath path) {
        return pathToIter(treeStore, path);
    }

    int getIndexOfIter(TreeIter iter) {
        return getIndexOfIter(treeStore, iter);
    }

    int getIndexOfPath(string path) {
        return getIndexOfPath(treeStore, path);
    }

    TreeIter pathToIter(TreeModelIF model, string path) {
        TreeIter iter = new TreeIter();
        model.getIter(iter, new TreePath(path));
        return iter;
    }

    TreeIter pathToIter(TreeModelIF model, TreePath path) {
        TreeIter iter = new TreeIter();
        model.getIter(iter, path);
        return iter;
    }

    int getIndexOfIter(TreeModelIF model, TreeIter iter) {
        return model.getValueInt(iter, EditorTreeIndices.MapId);
    }

    int getIndexOfPath(TreeModelIF model, string path) {
        return getIndexOfIter(model, pathToIter(path));
    }

    void updateTreeAppend(Node node, TreeIter iterator, Node focused = null) {
        treeStore.setValuesv(iterator, [EditorTreeIndices.NameColumn, EditorTreeIndices.VisibleColumn, EditorTreeIndices.MapId], [new Value(node.name), new Value(node.visible), new Value(nodeMapping.length)]);
        if (focused is node) {
            toFocusTree = iterator;
        }
        nodeMapping ~= node;
        
        foreach(child; node.children) {
            TreeIter iter = treeStore.createIter(iterator);
            updateTreeAppend(child, iter, focused);
        }
    }
public:
    /// The tree view that displays the nodes
    TreeView nodeTree;

    /// Button used to add new objects
    Button addNewObjectButton;

    /// Button used to delete the object(s) selected
    Button deleteSelectedObjectButton;

    this(Widget parent) {
        super(parent);

        nodeTree = new TreeView();
        treeStore = new TreeStore([GType.STRING, GType.BOOLEAN, GType.INT]);

        import std.stdio : writeln;
        nodeTree.setReorderable(true);

        nodeTree.addOnDragBegin((ctx, widget) {
            isMoving = true;
        });

        treeStore.addOnRowChanged((TreePath path, TreeIter iter, model) {
            if (!isMoving) return;
            isMoving = false;
            writeln("Node binding changed, updating tree and node structure...");
            Node indexNode = nodeMapping[getIndexOfIter(model, iter)];
            Node parentNode = SCENE.rootNode;

            // Don't allow dragging root node, nor placing anything over root node
            if (indexNode == SCENE.rootNode || path.getDepth() == 1) {
                updateTree(SCENE.focus);
                return;
            }
            
            // Non-destructively destroy the instance in the node tree
            indexNode.selfDestruct(false);

            if (path.getDepth() > 1 && path.up()) {
                TreeIter parent = pathToIter(path);
                parentNode = nodeMapping[getIndexOfIter(parent)];
            }

            parentNode.children ~= indexNode;
            indexNode.parent = parentNode;

            // TODO: Expand nodes
            return;
        });

        nameRenderer = new CellRendererText();
        nameRenderer.addOnEdited((path, text, widget) {
            TreeIter iter = pathToIter(path);
            int id = getIndexOfIter(iter);
            this.setName(iter, id, text);
        });
        nameRenderer.setProperty("editable", true);
        nameColumn = new TreeViewColumn("Name", nameRenderer, "text", EditorTreeIndices.NameColumn);
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

        visibleColumn = new TreeViewColumn("👁️", visibleRenderer, "active", EditorTreeIndices.VisibleColumn);
        visibleColumn.setAlignment(0.5f);
        nodeTree.appendColumn(visibleColumn);

        if (CONFIG.debugMode) nodeTree.appendColumn(new TreeViewColumn("IDs", nameRenderer, "text", EditorTreeIndices.MapId));

        nodeTree.setModel(treeStore);
        nodeTree.setReorderable(true);

        nodeTree.setActivateOnSingleClick(false);
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
            import scene.nodes;
            if (selectedItem() is null) return;

            int id = getIndexOfIter(selectedItem());

            // Don't allow deleting the root node.
            if (is(typeof(nodeMapping[id]) : RootNode)) {
                return;
            }

            Node parent = nodeMapping[id].parent;
            
            nodeMapping[id].selfDestruct();

            if (parent is null) {
                SCENE.changeFocus(SCENE.rootNode);
                updateTree(SCENE.rootNode);
                return;
            }

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

    /// Returns a TreeIter poiting to the currently selected item
    TreeIter selectedItem() {
        return nodeTree.getSelectedIter();
    }

    /// Propergate visibility modifies down through the tree from the TreeIter.
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

    /// Set the visibility flag for a single element from its TreeIter and id.
    void setVisibility(TreeIter iter, int id, bool visibility) {
        nodeMapping[id].visible = visibility;
        treeStore.setValue(iter, EditorTreeIndices.VisibleColumn, new Value(nodeMapping[id].visible));
    }

    /// Set the name for a single element from its TreeIter and id.
    void setName(TreeIter iter, int id, string newName) {
        nodeMapping[id].name = newName;
        treeStore.setValue(iter, EditorTreeIndices.NameColumn, new Value(newName));
    }

    /// Returns the name of the element the TreeIter and id point to.
    string getName(TreeIter iter) {
        return treeStore.getValueString(iter, EditorTreeIndices.NameColumn);
    }

    /// Update the tree structure.
    void updateTree(Node focused = null) {
        if (SCENE is null) return;
        nodeMapping = [];
        toFocusTree = null;

        treeStore.clear();
        TreeIter treeIterator = treeStore.createIter();
        updateTreeAppend(SCENE.rootNode, treeIterator, focused);
        nodeTree.expandAll();

        if (toFocusTree !is null) {
            nodeTree.getSelection().selectIter(toFocusTree);
        } else {
            nodeTree.getSelection().selectIter(treeIterator);
        }
    }
}
