import SwiftUI

enum WeReadPanel: String, Identifiable {
    case shelf
    case search

    var id: String { rawValue }
}

@MainActor
final class WeReadAssistant: ObservableObject {
    @Published var presentedPanel: WeReadPanel?
    @Published private(set) var recentBooks: [WeReadBook] = []
    @Published private(set) var searchResults: [WeReadSearchBook] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private let client: WeReadAPIClient

    init(client: WeReadAPIClient = WeReadAPIClient()) {
        self.client = client
    }

    func showShelf() {
        presentedPanel = .shelf
    }

    func showSearch() {
        presentedPanel = .search
    }

    func loadRecentBooks() async {
        await load {
            recentBooks = try await client.recentBooks()
        }
    }

    func search() async {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }
        await load {
            searchResults = try await client.searchBooks(keyword: keyword)
        }
    }

    private func load(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct WeReadAssistantPanel: View {
    let panel: WeReadPanel
    @ObservedObject var assistant: WeReadAssistant
    @ObservedObject var navigator: ReaderNavigator

    var body: some View {
        Group {
            switch panel {
            case .shelf:
                shelfView
            case .search:
                searchView
            }
        }
        .frame(minWidth: 620, minHeight: 480)
        .background(Color.white)
    }

    private var shelfView: some View {
        VStack(spacing: 0) {
            panelHeader("继续阅读", action: assistant.loadRecentBooks)
            Divider()
            resultContent(isEmpty: assistant.recentBooks.isEmpty) {
                List(assistant.recentBooks) { book in
                    bookButton(
                        title: book.title,
                        subtitle: shelfSubtitle(for: book),
                        deepLink: book.deepLink,
                        disabled: false
                    )
                }
                .listStyle(.plain)
            }
        }
        .task {
            if assistant.recentBooks.isEmpty {
                await assistant.loadRecentBooks()
            }
        }
    }

    private var searchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("搜索电子书", text: $assistant.searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .onSubmit { Task { await assistant.search() } }
                Button("搜索") {
                    Task { await assistant.search() }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(assistant.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            Divider()
            resultContent(isEmpty: assistant.searchResults.isEmpty) {
                List(assistant.searchResults) { book in
                    bookButton(
                        title: book.title,
                        subtitle: book.author,
                        deepLink: book.deepLink,
                        disabled: book.soldout
                    )
                }
                .listStyle(.plain)
            }
        }
    }

    private func panelHeader(
        _ title: String,
        action: @escaping () async -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Spacer()
            Button("刷新") {
                Task { await action() }
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func resultContent<Content: View>(
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if assistant.isLoading {
            placeholder("正在读取微信读书数据…", systemImage: "hourglass")
        } else if let message = assistant.errorMessage {
            placeholder(message, systemImage: "exclamationmark.triangle")
        } else if isEmpty {
            placeholder(
                panel == .shelf ? "没有找到正在阅读的书" : "输入书名开始搜索",
                systemImage: panel == .shelf ? "books.vertical" : "magnifyingglass"
            )
        } else {
            content()
        }
    }

    private func placeholder(_ message: String, systemImage: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func bookButton(
        title: String,
        subtitle: String,
        deepLink: String,
        disabled: Bool
    ) -> some View {
        Button {
            guard let url = URL(string: deepLink) else { return }
            navigator.open(url)
            assistant.presentedPanel = nil
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.closed")
                    .font(.title2)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(disabled ? "已下架 · \(subtitle)" : subtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func shelfSubtitle(for book: WeReadBook) -> String {
        var parts = [book.author]
        if let timestamp = book.readUpdateTime {
            let date = Date(timeIntervalSince1970: timestamp)
            parts.append("上次阅读：\(date.formatted(.dateTime.year().month().day()))")
        }
        return parts.joined(separator: " · ")
    }
}
