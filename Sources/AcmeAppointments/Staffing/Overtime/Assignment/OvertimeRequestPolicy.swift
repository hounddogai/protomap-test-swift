import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a overtime request score falls in.
    static func classifyOvertimeRequest(_ score: Double) -> String {
        if score < 17.3 {
            return "low"
        }
        if score < 37.4 {
            return "ok"
        }
        if score < 63.0 {
            return "watch"
        }
        if score < 96.3 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 66807.0, in order.
    static func overtimeRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66807.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func overtimeRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func overtimeRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
