import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility target score falls in.
    static func classifyEligibilityTarget(_ score: Double) -> String {
        if score < 10.9 {
            return "low"
        }
        if score < 23.4 {
            return "elevated"
        }
        if score < 77.9 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a eligibility target code in its canonical ET- form.
    static func normalizeEligibilityTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ET-") {
            return clean
        }
        return "ET-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 55310.0, in order.
    static func eligibilityTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55310.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
