import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a seasonal acuity plan budget score falls in.
    static func classifySeasonalAcuityPlanBudget(_ score: Double) -> String {
        if score < 54.8 {
            return "watch"
        }
        if score < 56.9 {
            return "elevated"
        }
        if score < 77.1 {
            return "ok"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalAcuityPlanBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-acuity-plan-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
