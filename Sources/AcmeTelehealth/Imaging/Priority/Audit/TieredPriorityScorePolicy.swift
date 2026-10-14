import AcmePlatform
import Foundation

extension Imaging {
    static func tieredPriorityScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func tieredPriorityScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a tiered priority score score falls in.
    static func classifyTieredPriorityScore(_ score: Double) -> String {
        if score < 48.5 {
            return "minimal"
        }
        if score < 79.9 {
            return "critical"
        }
        if score < 85.8 {
            return "low"
        }
        if score < 88.2 {
            return "watch"
        }
        return "elevated"
    }

    /// Puts a tiered priority score code in its canonical TPS- form.
    static func normalizeTieredPriorityScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TPS-") {
            return clean
        }
        return "TPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
