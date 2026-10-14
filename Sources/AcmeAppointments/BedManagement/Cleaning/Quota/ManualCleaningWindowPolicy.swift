import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 14686.0, in order.
    static func manualCleaningWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14686.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual cleaning window score falls in.
    static func classifyManualCleaningWindow(_ score: Double) -> String {
        if score < 36.4 {
            return "ok"
        }
        if score < 49.5 {
            return "medium"
        }
        if score < 64.2 {
            return "minimal"
        }
        return "watch"
    }

    static func manualCleaningWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
