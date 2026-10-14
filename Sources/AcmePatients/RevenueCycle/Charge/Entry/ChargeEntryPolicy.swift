import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a charge entry code in its canonical CE- form.
    static func normalizeChargeEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CE-") {
            return clean
        }
        return "CE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func chargeEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
