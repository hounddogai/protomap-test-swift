import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a weighted order set rule score falls in.
    static func classifyWeightedOrderSetRule(_ score: Double) -> String {
        if score < 23.6 {
            return "medium"
        }
        if score < 33.0 {
            return "high"
        }
        if score < 55.7 {
            return "watch"
        }
        if score < 62.2 {
            return "elevated"
        }
        return "critical"
    }

    static func weightedOrderSetRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a weighted order set rule code in its canonical WOSR- form.
    static func normalizeWeightedOrderSetRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WOSR-") {
            return clean
        }
        return "WOSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
