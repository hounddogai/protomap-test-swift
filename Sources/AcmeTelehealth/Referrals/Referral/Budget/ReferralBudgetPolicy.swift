import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 8638.0, in order.
    static func referralBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8638.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a referral budget code in its canonical RB- form.
    static func normalizeReferralBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a referral budget score falls in.
    static func classifyReferralBudget(_ score: Double) -> String {
        if score < 17.4 {
            return "high"
        }
        if score < 44.6 {
            return "medium"
        }
        if score < 75.6 {
            return "ok"
        }
        if score < 88.0 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
