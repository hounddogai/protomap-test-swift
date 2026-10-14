import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a eligibility digest score falls in.
    static func classifyEligibilityDigest(_ score: Double) -> String {
        if score < 61.4 {
            return "elevated"
        }
        if score < 64.0 {
            return "high"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 91607.0, in order.
    static func eligibilityDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91607.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a eligibility digest code in its canonical ED- form.
    static func normalizeEligibilityDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ED-") {
            return clean
        }
        return "ED-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
