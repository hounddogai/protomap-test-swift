import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization agreement score falls in.
    static func classifyAuthorizationAgreement(_ score: Double) -> String {
        if score < 18.2 {
            return "ok"
        }
        if score < 84.3 {
            return "high"
        }
        if score < 99.4 {
            return "watch"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 42003.0, in order.
    static func authorizationAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42003.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
