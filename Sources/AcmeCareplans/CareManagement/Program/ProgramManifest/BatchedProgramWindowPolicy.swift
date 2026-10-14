import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched program window score falls in.
    static func classifyBatchedProgramWindow(_ score: Double) -> String {
        if score < 43.0 {
            return "minimal"
        }
        if score < 89.6 {
            return "medium"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 34255.0, in order.
    static func batchedProgramWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34255.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedProgramWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
