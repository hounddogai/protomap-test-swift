import AcmePlatform
import Foundation

extension Consent {
    static func disclosureRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a disclosure rollup code in its canonical DR- form.
    static func normalizeDisclosureRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DR-") {
            return clean
        }
        return "DR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
