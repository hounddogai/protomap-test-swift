import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 61564.0, in order.
    static func cappedReferralRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61564.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a capped referral rollup code in its canonical CRR- form.
    static func normalizeCappedReferralRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRR-") {
            return clean
        }
        return "CRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
