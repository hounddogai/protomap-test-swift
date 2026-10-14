import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan agreement score falls in.
    static func classifyAcuityPlanAgreement(_ score: Double) -> String {
        if score < 5.2 {
            return "watch"
        }
        if score < 58.1 {
            return "low"
        }
        if score < 89.9 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a acuity plan agreement code in its canonical APA- form.
    static func normalizeAcuityPlanAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APA-") {
            return clean
        }
        return "APA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
