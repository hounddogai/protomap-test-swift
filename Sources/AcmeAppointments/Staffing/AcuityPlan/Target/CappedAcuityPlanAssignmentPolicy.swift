import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 76950.0, in order.
    static func cappedAcuityPlanAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76950.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped acuity plan assignment score falls in.
    static func classifyCappedAcuityPlanAssignment(_ score: Double) -> String {
        if score < 10.8 {
            return "medium"
        }
        if score < 71.7 {
            return "minimal"
        }
        if score < 86.9 {
            return "low"
        }
        return "watch"
    }

    static func cappedAcuityPlanAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedAcuityPlanAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-acuity-plan-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
