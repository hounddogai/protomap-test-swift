import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a assessment allocation code in its canonical AA- form.
    static func normalizeAssessmentAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func assessmentAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
