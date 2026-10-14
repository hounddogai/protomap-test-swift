import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingAcuityPlanAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-acuity-plan-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 99520.0, in order.
    static func rollingAcuityPlanAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99520.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
