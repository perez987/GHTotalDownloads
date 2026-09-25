#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct DownloadsReportSummary {
    let repositoryCount: Int
    let repositoriesWithDownloads: Int
    let totalDownloads: Int
}

struct DownloadsTableFormatter {
    private let nameWidth = 45
    private let countWidth = 15

    func header() -> [String] {
        [
            row(name: "REPOSITORY", count: "DOWNLOADS"),
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
        ]
    }

    func repositoryRow(name: String, downloads: Int) -> String {
        row(name: name, count: String(downloads))
    }

    func footer(totalDownloads: Int) -> [String] {
        [
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
            row(name: "TOTAL", count: String(totalDownloads)),
        ]
    }

    private func row(name: String, count: String) -> String {
        let left = truncate(name, to: nameWidth).padding(toLength: nameWidth, withPad: " ", startingAt: 0)
        let right = count.leftPadded(to: countWidth)
        return "\(left) \(right)"
    }

    private func truncate(_ value: String, to width: Int) -> String {
        guard value.count > width else {
            return value
        }

        let suffix = "…"
        let prefixCount = max(width - suffix.count, 0)
        return String(value.prefix(prefixCount)) + suffix
    }
}

struct DownloadsReportRunner {
    let username: String
    let token: String?

    private let formatter = DownloadsTableFormatter()

    func run(emit: @escaping @Sendable (String) async -> Void) async throws -> DownloadsReportSummary {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUsername.isEmpty == false else {
            throw GitHubAPIError.invalidUsername
        }

        let client = GitHubAPIClient(username: trimmedUsername, token: token)

        await emit("User: \(trimmedUsername)")
        await emit("Querying public repositories and release downloads...")
        await emit("")
        for line in formatter.header() {
            await emit(line)
        }

        var allRepositories: [GitHubRepository] = []
        var page = 1
        while true {
            let repositories = try await client.fetchRepositories(page: page)
            guard repositories.isEmpty == false else {
                break
            }

            allRepositories.append(contentsOf: repositories)
            if repositories.count < 100 {
                break
            }
            page += 1
        }

        var grandTotal = 0
        var repositoriesWithDownloads = 0

        for repository in allRepositories {
            try Task.checkCancellation()
            let downloads = try await fetchDownloads(for: repository.name, client: client)
            await emit(formatter.repositoryRow(name: repository.name, downloads: downloads))
            grandTotal += downloads
            if downloads > 0 {
                repositoriesWithDownloads += 1
            }
        }

        for line in formatter.footer(totalDownloads: grandTotal) {
            await emit(line)
        }
        await emit("")
        await emit("Public repositories analyzed: \(allRepositories.count)")
        await emit("Repositories with recorded downloads: \(repositoriesWithDownloads)")

        return DownloadsReportSummary(
            repositoryCount: allRepositories.count,
            repositoriesWithDownloads: repositoriesWithDownloads,
            totalDownloads: grandTotal
        )
    }

    private func fetchDownloads(for repositoryName: String, client: GitHubAPIClient) async throws -> Int {
        var page = 1
        var total = 0

        while true {
            let releases = try await client.fetchReleases(repositoryName: repositoryName, page: page)
            guard releases.isEmpty == false else {
                break
            }

            total += releases
                .flatMap(\.assets)
                .reduce(0) { partialResult, asset in
                    partialResult + asset.downloadCount
                }

            if releases.count < 100 {
                break
            }
            page += 1
        }

        return total
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        guard count < width else {
            return self
        }
        return String(repeating: " ", count: width - count) + self
    }
}
