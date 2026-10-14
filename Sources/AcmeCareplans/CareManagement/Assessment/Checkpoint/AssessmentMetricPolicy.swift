import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a assessment metric code in its canonical AM- form.
    static func normalizeAssessmentMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AM-") {
            return clean
        }
        return "AM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a assessment metric score falls in.
    static func classifyAssessmentMetric(_ score: Double) -> String {
        if score < 6.9 {
            return "minimal"
        }
        if score < 59.7 {
            return "medium"
        }
        if score < 62.8 {
            return "critical"
        }
        if score < 75.6 {
            return "high"
        }
        return "low"
    }
}
