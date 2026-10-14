import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 2504.0, in order.
    static func referralDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2504.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a referral digest code in its canonical RD- form.
    static func normalizeReferralDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RD-") {
            return clean
        }
        return "RD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
