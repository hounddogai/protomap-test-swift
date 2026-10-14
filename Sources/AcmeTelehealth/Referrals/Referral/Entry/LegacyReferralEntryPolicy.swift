import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a legacy referral entry code in its canonical LRE- form.
    static func normalizeLegacyReferralEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRE-") {
            return clean
        }
        return "LRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 60599.0, in order.
    static func legacyReferralEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60599.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyReferralEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
