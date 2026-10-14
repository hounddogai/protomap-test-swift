import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a lenient overtime assignment score falls in.
    static func classifyLenientOvertimeAssignment(_ score: Double) -> String {
        if score < 17.6 {
            return "high"
        }
        if score < 19.4 {
            return "watch"
        }
        if score < 61.1 {
            return "ok"
        }
        if score < 97.9 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 87691.0, in order.
    static func lenientOvertimeAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87691.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientOvertimeAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func lenientOvertimeAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
