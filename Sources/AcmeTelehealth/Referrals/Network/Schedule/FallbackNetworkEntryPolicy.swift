import AcmePlatform
import Foundation

extension Referrals {
    static func fallbackNetworkEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 68983.0, in order.
    static func fallbackNetworkEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68983.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a fallback network entry code in its canonical FNE- form.
    static func normalizeFallbackNetworkEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FNE-") {
            return clean
        }
        return "FNE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
