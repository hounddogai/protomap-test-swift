import AcmePlatform
import Foundation

extension Imaging {
    static func fallbackWorklistGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a fallback worklist group code in its canonical FWG- form.
    static func normalizeFallbackWorklistGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FWG-") {
            return clean
        }
        return "FWG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
