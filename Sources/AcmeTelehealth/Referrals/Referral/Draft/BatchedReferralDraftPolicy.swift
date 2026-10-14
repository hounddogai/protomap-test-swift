import AcmePlatform
import Foundation

extension Referrals {
    static func batchedReferralDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a batched referral draft score falls in.
    static func classifyBatchedReferralDraft(_ score: Double) -> String {
        if score < 33.1 {
            return "elevated"
        }
        if score < 43.3 {
            return "ok"
        }
        if score < 73.0 {
            return "minimal"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 26013.0, in order.
    static func batchedReferralDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26013.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched referral draft code in its canonical BRD- form.
    static func normalizeBatchedReferralDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRD-") {
            return clean
        }
        return "BRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
