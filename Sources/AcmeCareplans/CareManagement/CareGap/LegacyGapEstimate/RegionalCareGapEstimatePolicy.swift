import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 2885.0, in order.
    static func regionalCareGapEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2885.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalCareGapEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-care-gap-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalCareGapEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a regional care gap estimate score falls in.
    static func classifyRegionalCareGapEstimate(_ score: Double) -> String {
        if score < 20.9 {
            return "high"
        }
        if score < 23.5 {
            return "watch"
        }
        if score < 63.9 {
            return "ok"
        }
        if score < 65.5 {
            return "medium"
        }
        return "elevated"
    }
}
