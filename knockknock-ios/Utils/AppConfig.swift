import Foundation

enum AppConfig {
    static var wsBaseURL: String {
        string(for: "WS_BASE_URL") ?? "http://localhost:3000"
    }

    static var transitAPIKey: String {
        string(for: "TRANSIT_API_KEY") ?? ""
    }

    private static func string(for key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        if let value = ProcessInfo.processInfo.environment[key] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }
}
