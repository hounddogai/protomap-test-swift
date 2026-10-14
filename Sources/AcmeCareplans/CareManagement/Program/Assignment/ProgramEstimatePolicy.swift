import AcmePlatform
import Foundation

extension CareManagement {
    static func programEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a program estimate code in its canonical PE- form.
    static func normalizeProgramEstimateCode(_ code: String) -> String {
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
