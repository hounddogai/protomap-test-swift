import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictWorklistPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-worklist-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict worklist plan score falls in.
    static func classifyStrictWorklistPlan(_ score: Double) -> String {
        if score < 13.8 {
            return "medium"
        }
        if score < 43.3 {
            return "elevated"
        }
        return "high"
    }

    static func strictWorklistPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 38417.0, in order.
    static func strictWorklistPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38417.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
