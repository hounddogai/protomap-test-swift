import AcmePlatform
import Foundation

extension BedManagement {
    static func seasonalBedBoardPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a seasonal bed board preference code in its canonical SBBP- form.
    static func normalizeSeasonalBedBoardPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SBBP-") {
            return clean
        }
        return "SBBP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
