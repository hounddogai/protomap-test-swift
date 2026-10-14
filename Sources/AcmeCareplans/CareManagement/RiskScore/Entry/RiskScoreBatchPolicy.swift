import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeRiskScoreBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a risk score batch code in its canonical RSB- form.
    static func normalizeRiskScoreBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSB-") {
            return clean
        }
        return "RSB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func riskScoreBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a risk score batch score falls in.
    static func classifyRiskScoreBatch(_ score: Double) -> String {
        if score < 5.6 {
            return "medium"
        }
        if score < 25.6 {
            return "elevated"
        }
        if score < 46.8 {
            return "ok"
        }
        return "low"
    }
}
