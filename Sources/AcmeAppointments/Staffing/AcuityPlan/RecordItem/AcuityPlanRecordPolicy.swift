import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan record score falls in.
    static func classifyAcuityPlanRecord(_ score: Double) -> String {
        if score < 14.4 {
            return "low"
        }
        if score < 39.8 {
            return "watch"
        }
        return "high"
    }

    static func acuityPlanRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 80790.0, in order.
    static func acuityPlanRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80790.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
