import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 8813.0, in order.
    static func strictSpecimenEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8813.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictSpecimenEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func strictSpecimenEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
