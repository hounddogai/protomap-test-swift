import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback specimen tier code in its canonical FST- form.
    static func normalizeFallbackSpecimenTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FST-") {
            return clean
        }
        return "FST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackSpecimenTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
