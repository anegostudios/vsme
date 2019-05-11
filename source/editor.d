module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import components.headerbar;
import viewports.modelview;
import gtk.CssProvider;

struct Vector3 {
    float x;
    float y;
    float z;
}

enum VSME_TITLE = "VSME (Vintage Story Model Editor)";
class EditorWindow : ApplicationWindow {
public:
    ModelingViewport viewport;
    EditorHeaderBar headerBar;

    this(Application app) {
        super(app);

        addStylesheet(import("style.scss"));

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
}

CssProvider styleFromString(string styleSheet) {
    CssProvider provider = new CssProvider();
    provider.loadFromData(styleSheet);
    return provider;
}