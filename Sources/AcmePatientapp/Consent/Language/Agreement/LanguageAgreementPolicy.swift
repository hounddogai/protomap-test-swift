import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 29443.0, in order.
    static func languageAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29443.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func languageAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func languageAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
