module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import components.headerbar;
import viewports.modelview;

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

        // Set up header bars and other controls
        headerBar = new EditorHeaderBar(VSME_TITLE);

        // Set title, titlebar and show the window
        this.setTitlebar(headerBar);

        viewport = new ModelingViewport();
        this.add(viewport);
        this.showAll();
    }
}