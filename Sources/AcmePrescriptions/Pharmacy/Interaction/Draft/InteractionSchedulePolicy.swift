import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 40936.0, in order.
    static func interactionScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a interaction schedule score falls in.
    static func classifyInteractionSchedule(_ score: Double) -> String {
        if score < 26.5 {
            return "minimal"
        }
        if score < 33.0 {
            return "watch"
        }
        if score < 41.3 {
            return "low"
        }
        if score < 54.7 {
            return "ok"
        }
        return "critical"
    }
}
