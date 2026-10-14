import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall metric code in its canonical RM- form.
    static func normalizeRecallMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RM-") {
            return clean
        }
        return "RM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func recallMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a recall metric score falls in.
    static func classifyRecallMetric(_ score: Double) -> String {
        if score < 5.1 {
            return "minimal"
        }
        if score < 22.9 {
            return "low"
        }
        if score < 35.2 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeRecallMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
