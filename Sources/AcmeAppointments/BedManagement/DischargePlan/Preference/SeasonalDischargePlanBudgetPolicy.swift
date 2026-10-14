import AcmePlatform
import Foundation

extension BedManagement {
    static func seasonalDischargePlanBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a seasonal discharge plan budget score falls in.
    static func classifySeasonalDischargePlanBudget(_ score: Double) -> String {
        if score < 4.2 {
            return "elevated"
        }
        if score < 13.3 {
            return "minimal"
        }
        if score < 36.5 {
            return "watch"
        }
        if score < 84.4 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalDischargePlanBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-discharge-plan-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
