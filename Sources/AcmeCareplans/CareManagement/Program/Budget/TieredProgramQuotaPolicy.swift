import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredProgramQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 90450.0, in order.
    static func tieredProgramQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90450.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
