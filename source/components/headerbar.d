module components.headerbar;
import gtk.HeaderBar;

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
