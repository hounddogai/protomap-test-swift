import AcmePlatform
import Foundation

extension Referrals {
    static func manualEligibilityProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func manualEligibilityProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a manual eligibility proposal code in its canonical MEP- form.
    static func normalizeManualEligibilityProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MEP-") {
            return clean
        }
        return "MEP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 85928.0, in order.
    static func manualEligibilityProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
