import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a weighted alert plan score falls in.
    static func classifyWeightedAlertPlan(_ score: Double) -> String {
        if score < 13.7 {
            return "medium"
        }
        if score < 15.4 {
            return "minimal"
        }
        if score < 85.4 {
            return "ok"
        }
        if score < 88.2 {
            return "watch"
        }
        return "high"
    }

    static func weightedAlertPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a weighted alert plan code in its canonical WAP- form.
    static func normalizeWeightedAlertPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAP-") {
            return clean
        }
        return "WAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
