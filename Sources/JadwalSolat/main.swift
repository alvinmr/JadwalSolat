import AppKit

@MainActor
final class AppRunner {
    static func start() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

DispatchQueue.main.async {
    AppRunner.start()
}

dispatchMain()
