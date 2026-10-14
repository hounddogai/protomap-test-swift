import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualEligibilityManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-eligibility-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualEligibilityManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 31318.0, in order.
    static func manualEligibilityManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31318.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual eligibility manifest score falls in.
    static func classifyManualEligibilityManifest(_ score: Double) -> String {
        if score < 60.1 {
            return "watch"
        }
        if score < 73.1 {
            return "low"
        }
        return "high"
    }
}
