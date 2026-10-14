import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a alert plan score falls in.
    static func classifyAlertPlan(_ score: Double) -> String {
        if score < 26.8 {
            return "high"
        }
        if score < 59.3 {
            return "critical"
        }
        if score < 77.4 {
            return "low"
        }
        return "minimal"
    }

    /// Puts a alert plan code in its canonical AP- form.
    static func normalizeAlertPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AP-") {
            return clean
        }
        return "AP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
