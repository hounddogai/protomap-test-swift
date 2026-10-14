import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func acuityPlanGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 87300.0, in order.
    static func acuityPlanGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87300.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
