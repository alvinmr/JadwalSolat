import AppKit

@main
struct JadwalSolatApp {
    static var delegate: AppDelegate?

    @MainActor 
    static func main() {
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        
        // Strongly retain the delegate to survive AppKit's weak reference
        Self.delegate = appDelegate 
        
        app.delegate = appDelegate
        app.run()
    }
}
