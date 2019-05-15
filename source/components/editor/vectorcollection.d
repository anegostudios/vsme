/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module components.editor.vectorcollection;
import config;
import gtk.HBox;
import gtk.SpinButton;
import math;

/++
    A collection of color coded vector controls for X, Y and Z.

    Add callback to addOnValueChanged to 
+/
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

    /// Update the style context to match light/dark mode changes.
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

    /// Add delegate to the list of delegates that gets called when the value changes.
    void addOnValueChanged(void delegate(Vector3) cb) {
        callbacks ~= cb;
    }

    /// Returns the current value of the vector collection
    Vector3 getValue() {
        return Vector3(xButton.getValue(), yButton.getValue(), zButton.getValue());
    }

    /// Sets the value of the vector collection
    void setValue(Vector3 value) {
        xButton.setValue(value.x);
        yButton.setValue(value.y);
        zButton.setValue(value.z);
    }
}