module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import components.headerbar;
import viewports.modelview;
import gtk.CssProvider;
import gtk.Widget;
import gdk.Event;
import config;

struct Vector3 {
    float x;
    float y;
    float z;
}

enum VSME_TITLE = "VSME (Vintage Story Model Editor)";
class EditorWindow : ApplicationWindow {
private:
    CssProvider lightTheme;
    CssProvider darkTheme;

public:
    ModelingViewport viewport;
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

    void addStylesheet(string code) {
        this.getStyleContext().addProviderForScreen(this.getScreen(), styleFromString(code), STYLE_PROVIDER_PRIORITY_USER);
    }

    void switchToDarkMode() {

    }
}

CssProvider styleFromString(string styleSheet) {
    CssProvider provider = new CssProvider();
    provider.loadFromData(styleSheet);
    return provider;
}