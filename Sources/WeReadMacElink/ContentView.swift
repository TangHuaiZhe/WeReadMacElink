import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: ReaderSettings
    @ObservedObject var navigator: ReaderNavigator
    @State private var screenName = "正在识别显示器"

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            ReaderWebView(
                settings: settings,
                navigator: navigator,
                screenName: $screenName
            )
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(Color.white)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: navigator.goHome) {
                Label("首页", systemImage: "house")
            }
            Button(action: navigator.goBack) {
                Image(systemName: "chevron.left")
            }
            .help("后退")
            Button(action: navigator.goForward) {
                Image(systemName: "chevron.right")
            }
            .help("前进")
            Button(action: navigator.reload) {
                Image(systemName: "arrow.clockwise")
            }
            .help("刷新")

            Divider().frame(height: 24)

            settingButtons(
                title: "字号 \(Int((settings.textScale * 100).rounded()))%",
                decrease: settings.decreaseTextScale,
                increase: settings.increaseTextScale
            )

            settingButtons(
                title: "对比 \(Int((settings.contrast * 100).rounded()))%",
                decrease: settings.decreaseContrast,
                increase: settings.increaseContrast
            )

            settingButtons(
                title: "正文宽 \(Int((settings.contentWidth * 100).rounded()))%",
                decrease: settings.decreaseContentWidth,
                increase: settings.increaseContentWidth
            )

            Toggle("灰阶", isOn: $settings.grayscale)
            Toggle("减少动画", isOn: $settings.reduceMotion)

            Spacer(minLength: 8)
            Label(screenName, systemImage: "display")
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 14)
        .frame(height: 48)
    }

    private func settingButtons(
        title: String,
        decrease: @escaping () -> Void,
        increase: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            Button(action: decrease) {
                Image(systemName: "minus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)

            Text(title)
                .monospacedDigit()
                .frame(minWidth: 82)

            Button(action: increase) {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
        }
    }
}
