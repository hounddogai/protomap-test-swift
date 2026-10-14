import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a seasonal charge score score falls in.
    static func classifySeasonalChargeScore(_ score: Double) -> String {
        if score < 18.3 {
            return "high"
        }
        if score < 46.9 {
            return "medium"
        }
        return "watch"
    }

    static func mergeSeasonalChargeScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a seasonal charge score code in its canonical SCS- form.
    static func normalizeSeasonalChargeScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCS-") {
            return clean
        }
        return "SCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalChargeScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
