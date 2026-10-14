import AcmePlatform
import Foundation

extension Referrals {
    static func mergeReferralReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a referral review code in its canonical RR- form.
    static func normalizeReferralReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 14615.0, in order.
    static func referralReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14615.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func referralReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
