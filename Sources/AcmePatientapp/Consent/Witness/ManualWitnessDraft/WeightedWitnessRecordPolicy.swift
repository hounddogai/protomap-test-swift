import AcmePlatform
import Foundation

extension Consent {
    static func weightedWitnessRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a weighted witness record code in its canonical WWR- form.
    static func normalizeWeightedWitnessRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WWR-") {
            return clean
        }
        return "WWR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
