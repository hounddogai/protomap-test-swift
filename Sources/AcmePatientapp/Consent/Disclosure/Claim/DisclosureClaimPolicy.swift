import AcmePlatform
import Foundation

extension Consent {
    static func disclosureClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func disclosureClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a disclosure claim code in its canonical DC- form.
    static func normalizeDisclosureClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DC-") {
            return clean
        }
        return "DC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
