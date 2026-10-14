import AcmePlatform
import Foundation

extension Labs {
    static func specimenCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a specimen cycle code in its canonical SC- form.
    static func normalizeSpecimenCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SC-") {
            return clean
        }
        return "SC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
