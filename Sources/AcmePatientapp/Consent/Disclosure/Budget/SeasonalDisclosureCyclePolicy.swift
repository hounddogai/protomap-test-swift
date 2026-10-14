import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a seasonal disclosure cycle score falls in.
    static func classifySeasonalDisclosureCycle(_ score: Double) -> String {
        if score < 31.2 {
            return "minimal"
        }
        if score < 93.2 {
            return "critical"
        }
        return "low"
    }

    static func seasonalDisclosureCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a seasonal disclosure cycle code in its canonical SDC- form.
    static func normalizeSeasonalDisclosureCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDC-") {
            return clean
        }
        return "SDC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSeasonalDisclosureCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
