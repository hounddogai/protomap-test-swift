import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 23037.0, in order.
    static func networkMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23037.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func networkMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func networkMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a network milestone code in its canonical NM- form.
    static func normalizeNetworkMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NM-") {
            return clean
        }
        return "NM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
