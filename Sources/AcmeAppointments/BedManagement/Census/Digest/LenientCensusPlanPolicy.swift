import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient census plan code in its canonical LCP- form.
    static func normalizeLenientCensusPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCP-") {
            return clean
        }
        return "LCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientCensusPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
