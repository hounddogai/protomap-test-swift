import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 70455.0, in order.
    static func adaptiveInteractionDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70455.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveInteractionDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveInteractionDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
