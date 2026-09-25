import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct GitHubRepository: Decodable {
    let name: String
}

struct GitHubRelease: Decodable {
    let assets: [GitHubAsset]
}

struct GitHubAsset: Decodable {
    let downloadCount: Int

    private enum CodingKeys: String, CodingKey {
        case downloadCount = "download_count"
    }
}

struct GitHubAPIErrorPayload: Decodable {
    let message: String
}

enum GitHubAPIError: LocalizedError {
    case invalidUsername
    case invalidResponse
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Enter a GitHub username in Settings before running the report."
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case let .server(statusCode, message):
            return "GitHub API error (HTTP \(statusCode)): \(message)"
        }
    }
}

struct GitHubAPIClient {
    let username: String
    let token: String?

    private let apiBaseURL = URL(string: "https://api.github.com")!
    private let perPage = 100
    private let decoder = JSONDecoder()

    func fetchRepositories(page: Int) async throws -> [GitHubRepository] {
        try await get(
            path: "/users/\(username)/repos",
            queryItems: [
                URLQueryItem(name: "type", value: "owner"),
                URLQueryItem(name: "sort", value: "full_name"),
                URLQueryItem(name: "direction", value: "asc"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    func fetchReleases(repositoryName: String, page: Int) async throws -> [GitHubRelease] {
        try await get(
            path: "/repos/\(username)/\(repositoryName)/releases",
            queryItems: [
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        try Task.checkCancellation()

        var components = URLComponents(url: apiBaseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw GitHubAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("GHTotalDownloadsApp", forHTTPHeaderField: "User-Agent")

        let trimmedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedToken, trimmedToken.isEmpty == false {
            request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let payload = try? decoder.decode(GitHubAPIErrorPayload.self, from: data)
            throw GitHubAPIError.server(
                statusCode: httpResponse.statusCode,
                message: payload?.message ?? String(decoding: data, as: UTF8.self)
            )
        }

        return try decoder.decode(T.self, from: data)
    }
}
