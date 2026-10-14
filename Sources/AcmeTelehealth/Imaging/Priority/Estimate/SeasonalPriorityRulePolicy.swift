import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a seasonal priority rule score falls in.
    static func classifySeasonalPriorityRule(_ score: Double) -> String {
        if score < 7.1 {
            return "high"
        }
        if score < 49.3 {
            return "medium"
        }
        if score < 52.9 {
            return "ok"
        }
        if score < 75.8 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a seasonal priority rule code in its canonical SPR- form.
    static func normalizeSeasonalPriorityRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPR-") {
            return clean
        }
        return "SPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
