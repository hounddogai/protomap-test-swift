import AcmePlatform
import Foundation

extension CareManagement {
    static func programEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a program entry code in its canonical PE- form.
    static func normalizeProgramEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PE-") {
            return clean
        }
        return "PE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
