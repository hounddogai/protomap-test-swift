import AcmePlatform
import Foundation

extension Staffing {
    static func mergeScheduledCredentialRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 4496.0, in order.
    static func scheduledCredentialRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4496.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled credential request score falls in.
    static func classifyScheduledCredentialRequest(_ score: Double) -> String {
        if score < 50.2 {
            return "ok"
        }
        if score < 82.7 {
            return "critical"
        }
        if score < 82.9 {
            return "low"
        }
        return "high"
    }
}
