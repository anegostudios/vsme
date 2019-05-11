module components.headerbar;
import gtk.HeaderBar;
import gtk.Popover;
import gtk.Button;
import gtk.MenuButton;
import gtk.VBox;
import gtk.Widget : Widget;
import gio.Menu : Menu;
import gio.SimpleAction;
import glib.VariantType;
import gtk.ApplicationWindow;
import gtk.Image;
import gtk.FileChooserDialog;
import std.stdio;

class EditorHeaderBar : HeaderBar {
private:
    ApplicationWindow parent;
public:
    MenuButton newButton;
    MenuButton loadButton;
    MenuButton saveButton;
    Popover loadPopover;

    this(ApplicationWindow parent, string title) {
        super();

        this.parent = parent;

        initNew();
        initLoad();
        initSave();

        this.setShowCloseButton(true);
        this.setTitle(title);
        this.setSubtitle("Idle...");

        this.showAll();
    }

    void initNew() {
        newButton = new MenuButton();

        newButton.setFocusOnClick(false);
        Image newButtonHBG = new Image("document-new-symbolic", IconSize.MENU);
        newButton.add(newButtonHBG);

        this.packStart(newButton);
    }

    void initLoad() {
        loadButton = new MenuButton();

        SimpleAction fromProjectAction = new SimpleAction("openFromProject", null);
        fromProjectAction.addOnActivate((variant, simpleaction) {
            FileChooserDialog fileChooser = new FileChooserDialog("Open Project File", parent, GtkFileChooserAction.OPEN, ["Open"], [GtkResponseType.OK]);
            scope(exit) fileChooser.destroy();

            GtkResponseType resp = cast(GtkResponseType)fileChooser.run();
            if (resp == GtkResponseType.OK) {
                writeln(fileChooser.getFilename());

                return;
            }
        });
        parent.addAction(fromProjectAction);

        SimpleAction fromVSModelAction = new SimpleAction("openFromVSModel", null);
        fromVSModelAction.addOnActivate((variant, simpleaction) {
            FileChooserDialog fileChooser = new FileChooserDialog("Open Project File", parent, GtkFileChooserAction.OPEN, ["Open"], [GtkResponseType.OK]);
            scope(exit) fileChooser.destroy();

            GtkResponseType resp = cast(GtkResponseType)fileChooser.run();
            if (resp == GtkResponseType.OK) {
                writeln(fileChooser.getFilename());

                return;
            }
        });
        parent.addAction(fromVSModelAction);

        Menu model = new Menu();
        model.append("Open Project", "win.openFromProject");
        model.append("Import Model", "win.openFromVSModel");

        loadPopover = new Popover(loadButton, model);
        loadButton.setPopover(loadPopover);
        loadButton.setFocusOnClick(false);
        Image loadButtonHBG = new Image("document-open-symbolic", IconSize.MENU);
        loadButton.add(loadButtonHBG);
        this.packStart(loadButton);
    }

    void initSave() {
        saveButton = new MenuButton();

        saveButton.setFocusOnClick(false);
        Image saveButtonHBG = new Image("document-save-symbolic", IconSize.MENU);
        saveButton.add(saveButtonHBG);
        
        this.packStart(saveButton);
    }
}

enum LoadPopoverModel = `
<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <menu id="app-menu">
    <section>
        <item>
            <attribute name="label">Load From File</attribute>
            <attribute name="action">app.loadFromFile</attribute>
        </item>
        <item>
            <attribute name="label">Import from Vintage Story Model</attribute>
            <attribute name="action">app.importFromVS</attribute>
        </item>
    </section>
  </menu>
</interface>
`;