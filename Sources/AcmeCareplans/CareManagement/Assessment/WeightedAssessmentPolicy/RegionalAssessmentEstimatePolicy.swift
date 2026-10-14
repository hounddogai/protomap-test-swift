import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalAssessmentEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a regional assessment estimate code in its canonical RAE- form.
    static func normalizeRegionalAssessmentEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAE-") {
            return clean
        }
        return "RAE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
