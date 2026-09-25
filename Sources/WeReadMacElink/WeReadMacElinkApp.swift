import SwiftUI

@main
struct WeReadMacElinkApp: App {
    @StateObject private var settings = ReaderSettings()
    @StateObject private var navigator = ReaderNavigator()
    @StateObject private var assistant = WeReadAssistant()

    var body: some Scene {
        WindowGroup("微信读书 · 墨水屏") {
            ContentView(
                settings: settings,
                navigator: navigator,
                assistant: assistant
            )
        }
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("阅读") {
                Button("搜索微信读书") { assistant.showSearch() }
                    .keyboardShortcut("k", modifiers: .command)
                Divider()
                Button("上一页") { navigator.previousPage() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button("下一页") { navigator.nextPage() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Divider()
                Button("增大字号") { settings.increaseTextScale() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("减小字号") { settings.decreaseTextScale() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("恢复墨水屏默认设置") { settings.reset() }
            }
        }
    }
}
