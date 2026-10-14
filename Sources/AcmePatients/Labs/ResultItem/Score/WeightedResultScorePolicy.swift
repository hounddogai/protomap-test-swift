import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a weighted result score score falls in.
    static func classifyWeightedResultScore(_ score: Double) -> String {
        if score < 23.2 {
            return "high"
        }
        if score < 31.6 {
            return "critical"
        }
        if score < 54.6 {
            return "elevated"
        }
        if score < 58.1 {
            return "minimal"
        }
        return "medium"
    }

    static func weightedResultScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a weighted result score code in its canonical WRS- form.
    static func normalizeWeightedResultScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRS-") {
            return clean
        }
        return "WRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
