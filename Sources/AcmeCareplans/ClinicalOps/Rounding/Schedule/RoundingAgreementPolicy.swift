import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 54520.0, in order.
    static func roundingAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54520.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rounding agreement score falls in.
    static func classifyRoundingAgreement(_ score: Double) -> String {
        if score < 2.7 {
            return "elevated"
        }
        if score < 35.1 {
            return "low"
        }
        if score < 96.7 {
            return "high"
        }
        return "critical"
    }

    static func roundingAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
