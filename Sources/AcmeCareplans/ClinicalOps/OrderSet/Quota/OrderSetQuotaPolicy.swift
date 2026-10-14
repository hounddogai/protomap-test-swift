import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a order set quota score falls in.
    static func classifyOrderSetQuota(_ score: Double) -> String {
        if score < 25.9 {
            return "minimal"
        }
        if score < 50.6 {
            return "elevated"
        }
        if score < 70.0 {
            return "ok"
        }
        if score < 81.8 {
            return "watch"
        }
        return "low"
    }

    static func orderSetQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 5919.0, in order.
    static func orderSetQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5919.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
