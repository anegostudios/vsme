/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module components.editor.contextpop;
import components.editor.vectorcollection;
import config;
import gtk.Label;
import gtk.Popover;
import gtk.VBox;
import gtk.Widget;
import math;
import scene.scene;

/+
    A contextual popover that allows setting the translation, scale and rotation of an object.
++/
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
    /// Position VectorCollection
    VectorCollection position;

    /// Size VectorCollection
    VectorCollection size;

    /// Rotation VectorCollection
    VectorCollection rotation;

    /// Rotation Origin VectorCollection
    VectorCollection origin;

    /// Dock the popover to a widget, making it appear constantly until undocked.
    void dock(Widget dockedTo) {
        this.dockedTo = dockedTo;
        this.setRelativeTo(dockedTo);
        this.setModal(false);
    }

    /// Undock the popover from whatever widget it was docked to if any.
    void unDock() {
        this.dockedTo = null;
        this.setModal(true);
        this.setRelativeTo(parent);
    }

    /// Gets wether the popover is docked or not.
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

        this.setPosition(GtkPositionType.TOP);
        this.setConstrainTo(GtkPopoverConstraint.WINDOW);
        this.add(container);
    }

    /// Show the popover.
    void popUp(Vector2 position) {

        // Update the style contexts, in case the user changed from light to dark mode or vice versa.
        this.position.updateStyleContext();
        this.size.updateStyleContext();
        this.origin.updateStyleContext();
        this.rotation.updateStyleContext();

        // If it's docked, draw it docked.
        if (dockedTo !is null) {
            this.setPointingTo(new GdkRectangle(0, 0, 32, 32));
            this.showAll();
            return;
        }

        // Other wise, pop it up at the mouse cursor with a fancy animation.
        this.setPointingTo(new GdkRectangle(cast(int)position.x, cast(int)position.y, 2, 2));
        this.popup();
    }

    /// Hide the popover.
    void popDown() {
        if (dockedTo !is null) hide();
        else popdown();
        unDock();
    }
}
