import AcmePlatform
import Foundation

extension Staffing {
    static func mergeRollingSkillMixScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingSkillMixSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-skill-mix-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling skill mix schedule score falls in.
    static func classifyRollingSkillMixSchedule(_ score: Double) -> String {
        if score < 24.6 {
            return "minimal"
        }
        if score < 25.4 {
            return "low"
        }
        if score < 62.3 {
            return "elevated"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 31869.0, in order.
    static func rollingSkillMixScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31869.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
