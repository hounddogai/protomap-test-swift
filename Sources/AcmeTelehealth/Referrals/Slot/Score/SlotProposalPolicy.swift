import AcmePlatform
import Foundation

extension Referrals {
    static func slotProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 80986.0, in order.
    static func slotProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80986.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func slotProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a slot proposal code in its canonical SP- form.
    static func normalizeSlotProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SP-") {
            return clean
        }
        return "SP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
