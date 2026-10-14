import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure group code in its canonical DG- form.
    static func normalizeDisclosureGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DG-") {
            return clean
        }
        return "DG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func disclosureGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func disclosureGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
