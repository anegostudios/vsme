module editor;
import gtk.ApplicationWindow;
import gtk.Application;
import gtk.HeaderBar;

enum VSME_TITLE = "VSME (Vintage Story Model Editor)";

class EditorHeaderBar : HeaderBar {
public:
    this(string title) {
        super();

        this.setShowCloseButton(true);
        this.setTitle(title);
        this.setSubtitle("Idle...");

        this.showAll();
    }
}

class EditorWindow : ApplicationWindow {
public:
    EditorHeaderBar headerBar;

    this(Application app) {
        super(app);

        // Set up header bars and other controls
        headerBar = new EditorHeaderBar(VSME_TITLE);

        // Set title, titlebar and show the window
        this.setTitlebar(headerBar);
        this.showAll();
    }
}