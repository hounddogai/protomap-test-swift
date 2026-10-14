import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStatementNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("statement-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a statement notice code in its canonical SN- form.
    static func normalizeStatementNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SN-") {
            return clean
        }
        return "SN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func statementNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a statement notice score falls in.
    static func classifyStatementNotice(_ score: Double) -> String {
        if score < 77.3 {
            return "medium"
        }
        if score < 97.6 {
            return "low"
        }
        return "minimal"
    }
}
