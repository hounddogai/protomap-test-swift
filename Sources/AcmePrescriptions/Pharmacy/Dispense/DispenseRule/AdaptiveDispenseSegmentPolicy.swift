import AcmePlatform
import Foundation

extension Pharmacy {
    static func adaptiveDispenseSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive dispense segment code in its canonical ADS- form.
    static func normalizeAdaptiveDispenseSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ADS-") {
            return clean
        }
        return "ADS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
