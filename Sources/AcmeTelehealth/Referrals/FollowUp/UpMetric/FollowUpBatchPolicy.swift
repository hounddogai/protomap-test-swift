import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 42983.0, in order.
    static func followUpBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42983.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func followUpBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func followUpBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a follow up batch code in its canonical FUB- form.
    static func normalizeFollowUpBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUB-") {
            return clean
        }
        return "FUB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
