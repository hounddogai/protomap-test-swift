import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a acuity plan checkpoint score falls in.
    static func classifyAcuityPlanCheckpoint(_ score: Double) -> String {
        if score < 88.7 {
            return "high"
        }
        if score < 89.6 {
            return "ok"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 80940.0, in order.
    static func acuityPlanCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80940.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
