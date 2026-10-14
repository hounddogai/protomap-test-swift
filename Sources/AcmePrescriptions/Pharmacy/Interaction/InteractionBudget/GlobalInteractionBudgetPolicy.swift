import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalInteractionBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a global interaction budget code in its canonical GIB- form.
    static func normalizeGlobalInteractionBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GIB-") {
            return clean
        }
        return "GIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalInteractionBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
