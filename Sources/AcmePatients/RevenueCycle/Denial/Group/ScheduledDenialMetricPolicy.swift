import AcmePlatform
import Foundation

extension RevenueCycle {
    static func scheduledDenialMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 4250.0, in order.
    static func scheduledDenialMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4250.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
