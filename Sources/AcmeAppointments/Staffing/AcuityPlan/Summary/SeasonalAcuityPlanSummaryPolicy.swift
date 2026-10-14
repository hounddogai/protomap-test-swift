import AcmePlatform
import Foundation

extension Staffing {
    static func seasonalAcuityPlanSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal acuity plan summary score falls in.
    static func classifySeasonalAcuityPlanSummary(_ score: Double) -> String {
        if score < 36.8 {
            return "high"
        }
        if score < 83.4 {
            return "medium"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 96908.0, in order.
    static func seasonalAcuityPlanSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96908.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalAcuityPlanSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-acuity-plan-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
