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
import gtk.ColorChooserDialog;
import std.stdio;
import gdk.RGBA;
import config;
import scene.scene;
import utils;

class EditorHeaderBar : HeaderBar {
private:
    ApplicationWindow parent;

public:
    /// Load Button
    MenuButton newButton;
    Popover newPopover;

    MenuButton loadButton;
    Popover loadPopover;

    MenuButton saveButton;
    Popover savePopover;

    /// Hamburger Menu
    MenuButton hamburgerButton;
    Popover hamburgerPopover;


    this(ApplicationWindow parent, string title) {
        super();

        this.parent = parent;

        initNew();
        initLoad();
        initSave();

        initHamburger();

        this.setShowCloseButton(true);
        this.setTitle(title);
        this.setSubtitle("Untitled Project");

        this.showAll();
    }

    void initNew() {
        newButton = new MenuButton();


        SimpleAction newConfirmAction = new SimpleAction("confirmNew", null);
        newConfirmAction.addOnActivate((variant, simpleaction) {
            // Collect old scene
            doDestroy(SCENE);

            // New scene!
            SCENE = new Scene(true);

            this.setSubtitle("Untitled Project");
        });
        parent.addAction(newConfirmAction);

        Menu model = new Menu();
        Menu answer = new Menu();
        answer.append("Create New Project", "win.confirmNew");
        model.appendSection("Are you sure?", answer);

        newPopover = new Popover(newButton, model);

        newButton.setFocusOnClick(false);
        Image newButtonHBG = new Image("document-new-symbolic", IconSize.MENU);
        newButton.add(newButtonHBG);

        newButton.setPopover(newPopover);
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
                string file = fileChooser.getFilename();
                writeln("FileOP - Load: ", file);
                import scene.scene : loadFromVSMCFile;
                loadFromVSMCFile(file);
                this.setSubtitle(file);
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


        SimpleAction saveAction = new SimpleAction("saveProject", null);
        saveAction.addOnActivate((variant, simpleaction) {
            if (SCENE.outputPath is null) {
                FileChooserDialog fileChooser = new FileChooserDialog("Save Project...", parent, GtkFileChooserAction.SAVE, ["Save"], [GtkResponseType.OK]);
                scope(exit) fileChooser.destroy();

                GtkResponseType resp = cast(GtkResponseType)fileChooser.run();
                if (resp != GtkResponseType.OK) return;
        
                SCENE.outputPath = fileChooser.getFilename();
            }
            exportToVSMCFile(SCENE.outputPath);
            this.setSubtitle(SCENE.outputPath);
        });
        parent.addAction(saveAction);


        SimpleAction saveAsAction = new SimpleAction("saveProjectAs", null);
        saveAsAction.addOnActivate((variant, simpleaction) {
            FileChooserDialog fileChooser = new FileChooserDialog("Save Project As...", parent, GtkFileChooserAction.SAVE, ["Save"], [GtkResponseType.OK]);
            scope(exit) fileChooser.destroy();

            GtkResponseType resp = cast(GtkResponseType)fileChooser.run();
            if (resp != GtkResponseType.OK) return;
    
            SCENE.outputPath = fileChooser.getFilename();
            exportToVSMCFile(SCENE.outputPath);
            this.setSubtitle(SCENE.outputPath);
        });
        parent.addAction(saveAsAction);

        Menu model = new Menu();
        model.append("Save", "win.saveProject");
        model.append("Save As...", "win.saveProjectAs");


        savePopover = new Popover(saveButton, model);
        saveButton.setPopover(savePopover);
        saveButton.setFocusOnClick(false);
        Image saveButtonHBG = new Image("document-save-symbolic", IconSize.MENU);
        saveButton.add(saveButtonHBG);

        this.packStart(saveButton);
    }

    void initHamburger() {
        hamburgerButton = new MenuButton();

        SimpleAction setBGColorAction = new SimpleAction("setBGColor", null);
        setBGColorAction.addOnActivate((variant, simpleaction) {
            ColorChooserDialog colorChooser = new ColorChooserDialog("Select Background Color", parent);
            scope(exit) colorChooser.destroy();
            colorChooser.setUseAlpha(false);

            GtkResponseType resp = cast(GtkResponseType)colorChooser.run();

            // Only change color if OK was pressed.
            if (resp != GtkResponseType.OK) return;

            RGBA color;
            colorChooser.getRgba(color);

            CONFIG.backgroundColor[0] = color.red();
            CONFIG.backgroundColor[1] = color.green();
            CONFIG.backgroundColor[2] = color.blue();
        });
        parent.addAction(setBGColorAction);

        SimpleAction toggleDarkModeAction = new SimpleAction("toggleDarkMode", null);
        toggleDarkModeAction.addOnActivate((variant, simpleaction) {
            CONFIG.darkMode = !CONFIG.darkMode;
            parent.getSettings().setProperty("gtk-application-prefer-dark-theme", CONFIG.darkMode);
            parent.getStyleContext().invalidate();
        });
        parent.addAction(toggleDarkModeAction);

        Menu model = new Menu();
        model.append("Set Background", "win.setBGColor");
        model.append("Toggle Dark Mode", "win.toggleDarkMode");
        model.append("Preferences", "win.preferences");
        model.append("About", "win.about");
        model.append("Quit", "win.quit");

        hamburgerPopover = new Popover(hamburgerButton, model);
        hamburgerButton.setPopover(hamburgerPopover);
        hamburgerButton.setFocusOnClick(false);
        Image hamburgerButtonHBG = new Image("open-menu-symbolic", IconSize.MENU);
        hamburgerButton.add(hamburgerButtonHBG);

        this.packEnd(hamburgerButton);

    }
}