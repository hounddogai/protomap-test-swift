import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 66605.0, in order.
    static func regionalConsentFormRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional consent form rule score falls in.
    static func classifyRegionalConsentFormRule(_ score: Double) -> String {
        if score < 28.9 {
            return "ok"
        }
        if score < 65.8 {
            return "elevated"
        }
        return "high"
    }
}
