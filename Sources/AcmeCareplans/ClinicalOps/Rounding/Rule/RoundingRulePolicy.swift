import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rounding rule code in its canonical RR- form.
    static func normalizeRoundingRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rounding rule score falls in.
    static func classifyRoundingRule(_ score: Double) -> String {
        if score < 24.1 {
            return "critical"
        }
        if score < 79.7 {
            return "medium"
        }
        return "high"
    }

    static func roundingRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
