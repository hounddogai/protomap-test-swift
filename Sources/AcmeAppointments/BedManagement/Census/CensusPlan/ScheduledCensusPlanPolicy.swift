import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeScheduledCensusPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledCensusPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a scheduled census plan code in its canonical SCP- form.
    static func normalizeScheduledCensusPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCP-") {
            return clean
        }
        return "SCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled census plan score falls in.
    static func classifyScheduledCensusPlan(_ score: Double) -> String {
        if score < 18.5 {
            return "minimal"
        }
        if score < 38.0 {
            return "ok"
        }
        if score < 45.4 {
            return "watch"
        }
        return "high"
    }
}
