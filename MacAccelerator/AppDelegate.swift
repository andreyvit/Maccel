import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let engine = Engine()
    
    var configurationWindowController: ConfigurationWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        engine.reapply()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSLog("applicationShouldHandleReopen")
        if configurationWindowController == nil {
            configurationWindowController = ConfigurationWindowController(windowNibName: "ConfigurationWindowController")
        }
        let _ = configurationWindowController!.window
        configurationWindowController!.showWindow(nil)
        return false
    }

}
