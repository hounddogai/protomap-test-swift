import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 92987.0, in order.
    static func strictSlotAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92987.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict slot assignment score falls in.
    static func classifyStrictSlotAssignment(_ score: Double) -> String {
        if score < 7.2 {
            return "low"
        }
        if score < 45.4 {
            return "critical"
        }
        if score < 48.4 {
            return "high"
        }
        if score < 77.0 {
            return "minimal"
        }
        return "medium"
    }

    static func strictSlotAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictSlotAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
