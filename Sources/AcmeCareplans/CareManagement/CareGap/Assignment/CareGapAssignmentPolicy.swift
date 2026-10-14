import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a care gap assignment code in its canonical CGA- form.
    static func normalizeCareGapAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGA-") {
            return clean
        }
        return "CGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
