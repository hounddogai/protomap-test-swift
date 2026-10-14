import AcmePlatform
import Foundation

extension CareManagement {
    static func weightedAssessmentBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a weighted assessment budget code in its canonical WAB- form.
    static func normalizeWeightedAssessmentBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAB-") {
            return clean
        }
        return "WAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
