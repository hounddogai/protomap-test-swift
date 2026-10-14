import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedDischargePlanEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-discharge-plan-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func weightedDischargePlanEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a weighted discharge plan estimate score falls in.
    static func classifyWeightedDischargePlanEstimate(_ score: Double) -> String {
        if score < 90.8 {
            return "ok"
        }
        if score < 92.1 {
            return "critical"
        }
        if score < 93.6 {
            return "elevated"
        }
        if score < 97.2 {
            return "high"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 61210.0, in order.
    static func weightedDischargePlanEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61210.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
