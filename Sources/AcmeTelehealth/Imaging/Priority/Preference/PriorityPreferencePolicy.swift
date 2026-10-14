import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a priority preference score falls in.
    static func classifyPriorityPreference(_ score: Double) -> String {
        if score < 6.8 {
            return "minimal"
        }
        if score < 51.8 {
            return "low"
        }
        if score < 82.2 {
            return "critical"
        }
        if score < 96.5 {
            return "medium"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 5845.0, in order.
    static func priorityPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5845.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func priorityPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
