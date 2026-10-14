import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a primary acuity plan score score falls in.
    static func classifyPrimaryAcuityPlanScore(_ score: Double) -> String {
        if score < 63.9 {
            return "elevated"
        }
        if score < 77.9 {
            return "minimal"
        }
        if score < 80.8 {
            return "ok"
        }
        if score < 91.0 {
            return "medium"
        }
        return "critical"
    }

    /// Puts a primary acuity plan score code in its canonical PAPS- form.
    static func normalizePrimaryAcuityPlanScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAPS-") {
            return clean
        }
        return "PAPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
