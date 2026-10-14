import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a scheduled cleaning plan score falls in.
    static func classifyScheduledCleaningPlan(_ score: Double) -> String {
        if score < 2.2 {
            return "ok"
        }
        if score < 21.2 {
            return "minimal"
        }
        if score < 86.2 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 46563.0, in order.
    static func scheduledCleaningPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46563.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledCleaningPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-cleaning-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
