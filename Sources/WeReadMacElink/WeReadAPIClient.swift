import Foundation

struct WeReadSearchBook: Identifiable, Equatable {
    let bookId: String
    let deepLink: String
    let title: String
    let author: String
    let soldout: Bool

    var id: String { bookId }
}

struct WeReadReadingStatistics: Equatable {
    let today: Int
    let week: Int
    let year: Int

    static func durationText(seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours == 0 { return "\(minutes) 分钟" }
        if remainingMinutes == 0 { return "\(hours) 小时" }
        return "\(hours) 小时 \(remainingMinutes) 分"
    }
}

enum WeReadAPIError: LocalizedError, Equatable {
    case missingAPIKey
    case upgradeRequired(String)
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未找到 WEREAD_API_KEY。请先在环境变量中配置微信读书接口密钥。"
        case let .upgradeRequired(message):
            return message
        case let .server(message):
            return message
        case .invalidResponse:
            return "微信读书返回了无法识别的数据，请稍后重试。"
        }
    }
}

struct WeReadAPIClient {
    static let skillVersion = "1.0.4"

    private let endpoint = URL(string: "https://i.weread.qq.com/api/agent/gateway")!
    private let apiKey: String?
    private let session: URLSession

    init(
        apiKey: String? = ProcessInfo.processInfo.environment["WEREAD_API_KEY"],
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.session = session
    }

    func searchBooks(keyword: String) async throws -> [WeReadSearchBook] {
        let data = try await request(
            apiName: "/store/search",
            parameters: ["keyword": keyword, "scope": 10]
        )
        return try Self.decodeSearchBooks(data: data)
    }

    func readingStatistics(
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> WeReadReadingStatistics {
        let weeklyData = try await request(
            apiName: "/readdata/detail",
            parameters: ["mode": "weekly", "baseTime": 0]
        )
        let annualData = try await request(
            apiName: "/readdata/detail",
            parameters: ["mode": "annually", "baseTime": 0]
        )
        return try Self.decodeReadingStatistics(
            weeklyData: weeklyData,
            annualData: annualData,
            now: now,
            calendar: calendar
        )
    }

    static func decodeSearchBooks(data: Data) throws -> [WeReadSearchBook] {
        let response = try decoder.decode(SearchResponse.self, from: data)
        var seen = Set<String>()
        return response.results
            .flatMap(\.books)
            .compactMap { item in
                let book = item.bookInfo
                guard seen.insert(book.bookId).inserted else { return nil }
                return WeReadSearchBook(
                    bookId: book.bookId,
                    deepLink: book.deepLink,
                    title: book.title,
                    author: book.author,
                    soldout: book.soldout == 1
                )
            }
    }

    static func decodeReadingStatistics(
        weeklyData: Data,
        annualData: Data,
        now: Date,
        calendar: Calendar
    ) throws -> WeReadReadingStatistics {
        let weekly = try decoder.decode(ReadDataResponse.self, from: weeklyData)
        let annual = try decoder.decode(ReadDataResponse.self, from: annualData)
        let todayKey = String(Int(calendar.startOfDay(for: now).timeIntervalSince1970))
        return WeReadReadingStatistics(
            today: weekly.readTimes?[todayKey] ?? 0,
            week: weekly.totalReadTime,
            year: annual.totalReadTime
        )
    }

    private func request(
        apiName: String,
        parameters: [String: Any] = [:]
    ) async throws -> Data {
        guard let apiKey, !apiKey.isEmpty else {
            throw WeReadAPIError.missingAPIKey
        }

        var body = parameters
        body["api_name"] = apiName
        body["skill_version"] = Self.skillVersion

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw WeReadAPIError.invalidResponse
        }

        let metadata = try? Self.decoder.decode(GatewayMetadata.self, from: data)
        if let upgrade = metadata?.upgradeInfo {
            throw WeReadAPIError.upgradeRequired(upgrade.message)
        }
        if let errorCode = metadata?.errcode, errorCode != 0 {
            throw WeReadAPIError.server(metadata?.errmsg ?? "微信读书接口请求失败。")
        }
        return data
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

private struct GatewayMetadata: Decodable {
    let errcode: Int?
    let errmsg: String?
    let upgradeInfo: UpgradeInfo?

    struct UpgradeInfo: Decodable {
        let message: String
    }
}

private struct SearchResponse: Decodable {
    let results: [SearchGroup]
}

private struct SearchGroup: Decodable {
    let books: [SearchItem]
}

private struct SearchItem: Decodable {
    let bookInfo: SearchBookInfo
}

private struct SearchBookInfo: Decodable {
    let bookId: String
    let deepLink: String
    let title: String
    let author: String
    let soldout: Int?
}

private struct ReadDataResponse: Decodable {
    let totalReadTime: Int
    let readTimes: [String: Int]?
}
