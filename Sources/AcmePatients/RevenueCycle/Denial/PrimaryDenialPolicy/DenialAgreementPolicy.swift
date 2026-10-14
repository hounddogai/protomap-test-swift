import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 12328.0, in order.
    static func denialAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12328.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a denial agreement score falls in.
    static func classifyDenialAgreement(_ score: Double) -> String {
        if score < 2.8 {
            return "minimal"
        }
        if score < 71.5 {
            return "watch"
        }
        return "low"
    }
}
