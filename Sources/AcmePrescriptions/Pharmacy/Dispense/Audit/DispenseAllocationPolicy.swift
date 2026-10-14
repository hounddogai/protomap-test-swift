import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 92967.0, in order.
    static func dispenseAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92967.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a dispense allocation score falls in.
    static func classifyDispenseAllocation(_ score: Double) -> String {
        if score < 1.0 {
            return "minimal"
        }
        if score < 11.9 {
            return "low"
        }
        if score < 31.3 {
            return "high"
        }
        if score < 43.4 {
            return "watch"
        }
        return "critical"
    }
}
