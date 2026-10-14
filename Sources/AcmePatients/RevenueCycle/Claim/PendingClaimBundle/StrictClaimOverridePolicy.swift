import AcmePlatform
import Foundation

extension RevenueCycle {
    static func strictClaimOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a strict claim override code in its canonical SCO- form.
    static func normalizeStrictClaimOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCO-") {
            return clean
        }
        return "SCO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 7156.0, in order.
    static func strictClaimOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7156.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
