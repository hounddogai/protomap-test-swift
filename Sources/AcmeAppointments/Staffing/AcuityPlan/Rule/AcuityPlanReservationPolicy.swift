import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 18226.0, in order.
    static func acuityPlanReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18226.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a acuity plan reservation score falls in.
    static func classifyAcuityPlanReservation(_ score: Double) -> String {
        if score < 44.0 {
            return "minimal"
        }
        if score < 67.2 {
            return "critical"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
