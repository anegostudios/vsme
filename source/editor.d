/*
    Copyright © 2019 Clipsey & Anego Studios

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import components.headerbar;
import viewports.modelview;
import gtk.CssProvider;
import gtk.Widget;
import gdk.Event;
import config;

/++
    The main application window.
+/
class EditorWindow : ApplicationWindow {
private:
    CssProvider lightTheme;
    CssProvider darkTheme;

public:
    /// The 3D modeling viewport.
    ModelingViewport viewport;

    /// The header bar
    EditorHeaderBar headerBar;

    this(Application app) {
        super(app);

        this.Window.addOnSizeAllocate((widget, allocation) {
            this.Window.getSize(CONFIG.ui.window.width, CONFIG.ui.window.height);
        });
        
        this.Window.addOnWindowState((GdkEventWindowState* ev, Widget widget) {
            CONFIG.ui.window.maximized = (ev.newWindowState & WindowState.MAXIMIZED) != 0;
            CONFIG.ui.window.fullscreen = (ev.newWindowState & WindowState.FULLSCREEN) != 0;
            return false;
        });

        this.Window.setDefaultSize(CONFIG.ui.window.width, CONFIG.ui.window.height);
        if (CONFIG.ui.window.maximized) this.maximize();
        if (CONFIG.ui.window.fullscreen) this.fullscreen();

        addStylesheet(import("style.scss"));
        this.getSettings().setProperty("gtk-application-prefer-dark-theme", CONFIG.darkMode);

        // Set up header bars and other controls
        headerBar = new EditorHeaderBar(this, VSME_TITLE);

        // Set title, titlebar and show the window
        this.setTitlebar(headerBar);

        viewport = new ModelingViewport(this);
        this.add(viewport);
        this.showAll();
    }

    /// Add stylesheet to screen
    final void addStylesheet(string code) {
        this.getStyleContext().addProviderForScreen(this.getScreen(), styleFromString(code), STYLE_PROVIDER_PRIORITY_USER);
    }
}

/++
    Returns a CSS provider from a string of css data.
+/
CssProvider styleFromString(string styleSheet) {
    CssProvider provider = new CssProvider();
    provider.loadFromData(styleSheet);
    return provider;
}