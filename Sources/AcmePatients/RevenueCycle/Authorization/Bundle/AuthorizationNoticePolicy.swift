import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization notice score falls in.
    static func classifyAuthorizationNotice(_ score: Double) -> String {
        if score < 30.2 {
            return "medium"
        }
        if score < 53.7 {
            return "minimal"
        }
        if score < 95.1 {
            return "ok"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 47836.0, in order.
    static func authorizationNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47836.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
