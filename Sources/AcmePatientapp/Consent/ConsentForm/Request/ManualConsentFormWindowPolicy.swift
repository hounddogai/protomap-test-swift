import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a manual consent form window score falls in.
    static func classifyManualConsentFormWindow(_ score: Double) -> String {
        if score < 24.6 {
            return "medium"
        }
        if score < 50.5 {
            return "minimal"
        }
        if score < 57.0 {
            return "high"
        }
        if score < 64.2 {
            return "critical"
        }
        return "watch"
    }

    static func manualConsentFormWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func manualConsentFormWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 23087.0, in order.
    static func manualConsentFormWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23087.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
