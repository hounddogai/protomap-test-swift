import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 95191.0, in order.
    static func regionalRiskScoreReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95191.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalRiskScoreReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
