import SwiftUI

@main
struct GHTotalDownloadsApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 760, idealWidth: 760, maxWidth: 760, minHeight: 680, idealHeight: 680, maxHeight: 680)
        }
        .defaultSize(width: 820, height: 680)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .frame(minWidth: 640, idealWidth: 640, maxWidth: 640, minHeight: 560, idealHeight: 560, maxHeight: 560)
        }

        Window(settings.text(.language), id: "language-selector") {
            LanguageSelectorView()
                .environmentObject(settings)
                .frame(minWidth: 460, idealWidth: 460, maxWidth: 460, minHeight: 340, idealHeight: 340, maxHeight: 340)
        }
        .defaultSize(width: 460, height: 340)
        .windowResizability(.contentSize)
    }
}
