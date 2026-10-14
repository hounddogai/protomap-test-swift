import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning budget score falls in.
    static func classifyCleaningBudget(_ score: Double) -> String {
        if score < 19.5 {
            return "ok"
        }
        if score < 81.0 {
            return "low"
        }
        return "watch"
    }

    static func cleaningBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cleaningBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
