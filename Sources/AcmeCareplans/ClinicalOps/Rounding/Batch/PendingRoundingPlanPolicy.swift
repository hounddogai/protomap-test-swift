import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a pending rounding plan score falls in.
    static func classifyPendingRoundingPlan(_ score: Double) -> String {
        if score < 39.0 {
            return "ok"
        }
        if score < 53.0 {
            return "watch"
        }
        if score < 73.3 {
            return "low"
        }
        return "medium"
    }

    /// Puts a pending rounding plan code in its canonical PRP- form.
    static func normalizePendingRoundingPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRP-") {
            return clean
        }
        return "PRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
