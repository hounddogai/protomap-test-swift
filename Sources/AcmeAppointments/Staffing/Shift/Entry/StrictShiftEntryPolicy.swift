import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a strict shift entry score falls in.
    static func classifyStrictShiftEntry(_ score: Double) -> String {
        if score < 8.8 {
            return "watch"
        }
        if score < 44.5 {
            return "low"
        }
        if score < 45.7 {
            return "medium"
        }
        if score < 95.0 {
            return "critical"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 25970.0, in order.
    static func strictShiftEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 25970.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictShiftEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
