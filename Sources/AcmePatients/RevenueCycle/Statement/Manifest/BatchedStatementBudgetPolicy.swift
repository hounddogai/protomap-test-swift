import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedStatementBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a batched statement budget score falls in.
    static func classifyBatchedStatementBudget(_ score: Double) -> String {
        if score < 17.4 {
            return "elevated"
        }
        if score < 51.9 {
            return "medium"
        }
        if score < 54.4 {
            return "ok"
        }
        return "low"
    }

    static func batchedStatementBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 98022.0, in order.
    static func batchedStatementBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98022.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
