import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback panel preference code in its canonical FPP- form.
    static func normalizeFallbackPanelPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPP-") {
            return clean
        }
        return "FPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackPanelPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
