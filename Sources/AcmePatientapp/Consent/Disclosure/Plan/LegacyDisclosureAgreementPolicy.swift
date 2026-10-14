import AcmePlatform
import Foundation

extension Consent {
    static func legacyDisclosureAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 50477.0, in order.
    static func legacyDisclosureAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50477.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
