import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 69725.0, in order.
    static func rollingCleaningSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69725.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingCleaningSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func rollingCleaningSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
