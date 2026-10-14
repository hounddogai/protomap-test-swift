import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a statement cycle code in its canonical SC- form.
    static func normalizeStatementCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SC-") {
            return clean
        }
        return "SC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a statement cycle score falls in.
    static func classifyStatementCycle(_ score: Double) -> String {
        if score < 11.0 {
            return "critical"
        }
        if score < 79.3 {
            return "watch"
        }
        if score < 87.9 {
            return "minimal"
        }
        return "ok"
    }

    static func statementCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
