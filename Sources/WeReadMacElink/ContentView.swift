import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: ReaderSettings
    @ObservedObject var navigator: ReaderNavigator
    @ObservedObject var assistant: WeReadAssistant
    @State private var screenName = "正在识别显示器"

    var body: some View {
        VStack(spacing: 0) {
            controls
            readingStatisticsBar
            Divider()
            ReaderWebView(
                settings: settings,
                navigator: navigator,
                screenName: $screenName
            )
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(Color.white)
        .sheet(isPresented: $assistant.isSearchPresented) {
            WeReadAssistantPanel(
                assistant: assistant,
                navigator: navigator
            )
        }
        .task {
            await refreshStatistics()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshStatistics() }
        }
        .onChange(of: navigator.currentBookId) { bookId in
            guard let bookId else {
                assistant.clearBookReadingStatistics()
                return
            }
            Task { await assistant.refreshBookReadingStatistics(bookId: bookId) }
        }
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

            Button(action: assistant.showSearch) {
                Label("搜索", systemImage: "magnifyingglass")
            }
            .help("搜索微信读书电子书（⌘K）")

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
            if let progress = navigator.readingProgress {
                Divider().frame(height: 24)
                HStack(spacing: 7) {
                    Text("全书 \(progress)%")
                        .monospacedDigit()
                    ProgressView(value: Double(progress), total: 100)
                        .progressViewStyle(.linear)
                        .frame(width: 72)
                }
                .help("微信读书官方阅读进度")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("全书阅读进度 \(progress)%")
            }

            Spacer(minLength: 8)
            Label(screenName, systemImage: "display")
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 14)
        .frame(height: 48)
    }

    private var readingStatisticsBar: some View {
        HStack(spacing: 0) {
            Label("阅读时长", systemImage: "clock")
                .fontWeight(.semibold)

            if let statistics = assistant.readingStatistics {
                statistic("今天", seconds: statistics.today)
                statistic("本周", seconds: statistics.week)
                statistic("本年", seconds: statistics.year)
            } else {
                Text(assistant.statisticsErrorMessage == nil ? "正在读取…" : "暂时无法获取")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 18)
                    .help(assistant.statisticsErrorMessage ?? "")
            }

            if let book = assistant.bookReadingStatistics,
               book.bookId == navigator.currentBookId {
                statistic("本书", seconds: book.readingTime)
                if let remaining = book.estimatedRemainingTime {
                    statistic("预计剩余", seconds: remaining)
                }
            }

            Spacer()
            Button {
                Task { await refreshStatistics() }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(assistant.isStatisticsLoading || assistant.isBookStatisticsLoading)
            .help("刷新微信读书官方阅读统计")
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func refreshStatistics() async {
        await assistant.refreshReadingStatistics()
        if let bookId = navigator.currentBookId {
            await assistant.refreshBookReadingStatistics(bookId: bookId)
        }
    }

    private func statistic(_ label: String, seconds: Int) -> some View {
        HStack(spacing: 7) {
            Divider().frame(height: 16)
            Text(label)
                .foregroundStyle(.secondary)
            Text(WeReadReadingStatistics.durationText(seconds: seconds))
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .padding(.leading, 18)
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
