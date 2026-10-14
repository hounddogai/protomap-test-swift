import AcmePlatform
import Foundation

extension Consent {
    static func regionalConsentFormEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 10496.0, in order.
    static func regionalConsentFormEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10496.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional consent form entry score falls in.
    static func classifyRegionalConsentFormEntry(_ score: Double) -> String {
        if score < 65.2 {
            return "ok"
        }
        if score < 66.0 {
            return "medium"
        }
        return "critical"
    }

    static func regionalConsentFormEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
