import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyCareGapQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-care-gap-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyCareGapQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 65871.0, in order.
    static func legacyCareGapQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65871.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a legacy care gap quota score falls in.
    static func classifyLegacyCareGapQuota(_ score: Double) -> String {
        if score < 63.9 {
            return "ok"
        }
        if score < 75.8 {
            return "critical"
        }
        if score < 94.4 {
            return "watch"
        }
        return "medium"
    }
}
