import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalCareGapSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalCareGapSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 82336.0, in order.
    static func regionalCareGapSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82336.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
