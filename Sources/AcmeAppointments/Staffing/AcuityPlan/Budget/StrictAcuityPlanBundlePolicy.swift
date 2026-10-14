import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictAcuityPlanBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-acuity-plan-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict acuity plan bundle score falls in.
    static func classifyStrictAcuityPlanBundle(_ score: Double) -> String {
        if score < 80.2 {
            return "low"
        }
        if score < 85.1 {
            return "high"
        }
        if score < 94.8 {
            return "critical"
        }
        if score < 98.0 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 7675.0, in order.
    static func strictAcuityPlanBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7675.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
