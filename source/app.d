import std.stdio;
import gtk.ApplicationWindow;
import gtk.Application;
import editor;

int main(string[] args)
{
	auto app = new Application("com.anegostudios.vsme", GApplicationFlags.FLAGS_NONE);
	app.addOnActivate((GioApplication appx) { new EditorWindow(app); });
	return app.run(args);
}