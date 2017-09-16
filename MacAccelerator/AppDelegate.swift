import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let engine = Engine()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        engine.reapply()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

}
