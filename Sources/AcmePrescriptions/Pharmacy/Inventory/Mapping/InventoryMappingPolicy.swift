import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 93462.0, in order.
    static func inventoryMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93462.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func inventoryMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a inventory mapping score falls in.
    static func classifyInventoryMapping(_ score: Double) -> String {
        if score < 6.0 {
            return "watch"
        }
        if score < 36.0 {
            return "low"
        }
        if score < 36.2 {
            return "medium"
        }
        if score < 50.5 {
            return "critical"
        }
        return "elevated"
    }
}
