import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending denial override score falls in.
    static func classifyPendingDenialOverride(_ score: Double) -> String {
        if score < 35.0 {
            return "elevated"
        }
        if score < 99.4 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a pending denial override code in its canonical PDO- form.
    static func normalizePendingDenialOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDO-") {
            return clean
        }
        return "PDO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingDenialOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingDenialOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
