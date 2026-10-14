import AcmePlatform
import Foundation

extension Labs {
    static func courierPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a courier policy code in its canonical CP- form.
    static func normalizeCourierPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
