import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a bed board allocation score falls in.
    static func classifyBedBoardAllocation(_ score: Double) -> String {
        if score < 79.8 {
            return "watch"
        }
        if score < 82.9 {
            return "low"
        }
        if score < 85.3 {
            return "ok"
        }
        return "medium"
    }

    static func bedBoardAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 91505.0, in order.
    static func bedBoardAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91505.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
