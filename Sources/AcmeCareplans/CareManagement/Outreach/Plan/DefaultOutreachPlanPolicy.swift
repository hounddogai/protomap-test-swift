import AcmePlatform
import Foundation

extension CareManagement {
    static func defaultOutreachPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a default outreach plan code in its canonical DOP- form.
    static func normalizeDefaultOutreachPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DOP-") {
            return clean
        }
        return "DOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
