/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module components.editor.projection;
import components.glviewport;
import config;
import gtk.StackSwitcher;
import gtk.ToggleButton;

/++
    A switch that allows the user to switch the projection used.
+/
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