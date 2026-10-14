import AcmePlatform
import Foundation

extension Imaging {
    static func primaryReadReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 58511.0, in order.
    static func primaryReadReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58511.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
