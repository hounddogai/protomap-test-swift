import AcmePlatform
import Foundation

extension Consent {
    /// Puts a legacy disclosure baseline code in its canonical LDB- form.
    static func normalizeLegacyDisclosureBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDB-") {
            return clean
        }
        return "LDB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 63700.0, in order.
    static func legacyDisclosureBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63700.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyDisclosureBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
