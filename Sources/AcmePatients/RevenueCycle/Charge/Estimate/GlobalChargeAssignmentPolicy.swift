import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 42360.0, in order.
    static func globalChargeAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42360.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalChargeAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-charge-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global charge assignment score falls in.
    static func classifyGlobalChargeAssignment(_ score: Double) -> String {
        if score < 45.6 {
            return "critical"
        }
        if score < 58.5 {
            return "ok"
        }
        return "low"
    }
}
