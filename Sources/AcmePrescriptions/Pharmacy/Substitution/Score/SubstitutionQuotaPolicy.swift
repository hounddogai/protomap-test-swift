import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a substitution quota score falls in.
    static func classifySubstitutionQuota(_ score: Double) -> String {
        if score < 16.7 {
            return "minimal"
        }
        if score < 73.7 {
            return "low"
        }
        if score < 99.7 {
            return "high"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 7388.0, in order.
    static func substitutionQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7388.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func substitutionQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func substitutionQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.5
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
