import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted dispense mapping code in its canonical WDM- form.
    static func normalizeWeightedDispenseMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WDM-") {
            return clean
        }
        return "WDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedDispenseMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
