import SwiftUI

@main
struct BearHelperLauncherApp: App {
    init() {
    }

    var body: some Scene {
        // Esto oculta completamente cualquier ventana de la aplicación
        Settings {
            EmptyView()
        }
    }
}
