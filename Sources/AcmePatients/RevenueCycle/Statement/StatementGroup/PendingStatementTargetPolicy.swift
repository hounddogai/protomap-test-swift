import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending statement target score falls in.
    static func classifyPendingStatementTarget(_ score: Double) -> String {
        if score < 3.3 {
            return "ok"
        }
        if score < 49.9 {
            return "watch"
        }
        if score < 64.4 {
            return "critical"
        }
        if score < 65.5 {
            return "medium"
        }
        return "low"
    }

    static func pendingStatementTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a pending statement target code in its canonical PST- form.
    static func normalizePendingStatementTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PST-") {
            return clean
        }
        return "PST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
