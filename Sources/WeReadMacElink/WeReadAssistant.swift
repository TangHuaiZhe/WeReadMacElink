import SwiftUI

@MainActor
final class WeReadAssistant: ObservableObject {
    @Published var isSearchPresented = false
    @Published private(set) var searchResults: [WeReadSearchBook] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private let client: WeReadAPIClient

    init(client: WeReadAPIClient = WeReadAPIClient()) {
        self.client = client
    }

    func showSearch() {
        isSearchPresented = true
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
    @ObservedObject var assistant: WeReadAssistant
    @ObservedObject var navigator: ReaderNavigator

    var body: some View {
        searchView
        .frame(minWidth: 620, minHeight: 480)
        .background(Color.white)
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
            placeholder("输入书名开始搜索", systemImage: "magnifyingglass")
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
            assistant.isSearchPresented = false
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
}
