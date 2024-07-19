import SwiftUI

@main
struct BearHelperLauncherApp: App {
    init() {
        // Aquí puedes realizar cualquier configuración necesaria sin mostrar una ventana
        // Por ejemplo, podrías lanzar un proceso en segundo plano, etc.
    }

    var body: some Scene {
        // No crear ninguna ventana
        Settings {
            EmptyView()
        }
    }
}
