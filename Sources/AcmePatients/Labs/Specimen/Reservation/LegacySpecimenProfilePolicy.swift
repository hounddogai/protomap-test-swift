import AcmePlatform
import Foundation

extension Labs {
    static func legacySpecimenProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a legacy specimen profile code in its canonical LSP- form.
    static func normalizeLegacySpecimenProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSP-") {
            return clean
        }
        return "LSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
