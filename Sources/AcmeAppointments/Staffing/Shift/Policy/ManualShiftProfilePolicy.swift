import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a manual shift profile score falls in.
    static func classifyManualShiftProfile(_ score: Double) -> String {
        if score < 64.6 {
            return "ok"
        }
        if score < 80.3 {
            return "elevated"
        }
        return "medium"
    }

    static func manualShiftProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 88828.0, in order.
    static func manualShiftProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88828.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
