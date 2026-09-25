import Combine
import Foundation

#if canImport(AppKit)
    import AppKit
#endif

@MainActor
final class AppViewModel: ObservableObject {
    enum RunState {
        case idle
        case running
        case succeeded
        case failed(String)
        case cancelled

        var localizationKey: L10nKey {
            switch self {
            case .idle:
                return .runStateReady
            case .running:
                return .runStateRunning
            case .succeeded:
                return .runStateCompleted
            case .failed:
                return .runStateFailed
            case .cancelled:
                return .runStateCancelled
            }
        }

        @MainActor func title(in settings: SettingsStore) -> String {
            settings.text(localizationKey)
        }
    }

    @Published private(set) var outputLines: [String] = []
    @Published private(set) var runState: RunState = .idle
    @Published private(set) var lastSummary: DownloadsReportSummary?

    private var currentTask: Task<Void, Never>?

    var isRunning: Bool {
        if case .running = runState {
            return true
        }
        return false
    }

    func run(username: String, token: String?) {
        currentTask?.cancel()
        outputLines = []
        lastSummary = nil
        runState = .running

        currentTask = Task {
            do {
                let summary = try await DownloadsReportRunner(username: username, token: token).run { [weak self = self] line in
                    await self?.appendLine(line)
                }
                lastSummary = summary
                runState = .succeeded
            } catch {
                if isCancellationError(error) {
                    appendLine("\nRun cancelled")
                    runState = .cancelled
                    currentTask = nil
                    return
                }

                appendLine("")
                appendLine(error.localizedDescription)
                runState = .failed(error.localizedDescription)
            }
            currentTask = nil
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == URLError.cancelled.rawValue {
            return true
        }

        return false
    }

    func cancel() {
        currentTask?.cancel()
    }

    func clearOutput() {
        outputLines.removeAll()
    }

    func copyOutput() {
        let contents = outputLines.joined(separator: "\n")
        #if canImport(AppKit)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(contents, forType: .string)
        #else
            _ = contents
        #endif
    }

    private func appendLine(_ line: String) {
        outputLines.append(line)
    }
}
