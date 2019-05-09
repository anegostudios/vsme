module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import components.headerbar;
import components.glviewport;

enum VSME_TITLE = "VSME (Vintage Story Model Editor)";
class EditorWindow : ApplicationWindow {
public:
    EditorViewport viewport;
    EditorHeaderBar headerBar;

    this(Application app) {
        super(app);

        // Set up header bars and other controls
        headerBar = new EditorHeaderBar(VSME_TITLE);

        // Set title, titlebar and show the window
        this.setTitlebar(headerBar);

        viewport = new EditorViewport(this, (context, area) {
            return false;
        });
        this.add(viewport);
        this.showAll();
    }
}