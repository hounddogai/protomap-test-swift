import AcmePlatform
import Foundation

extension Consent {
    static func mergeRevocationQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func revocationQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a revocation quota score falls in.
    static func classifyRevocationQuota(_ score: Double) -> String {
        if score < 41.0 {
            return "ok"
        }
        if score < 70.0 {
            return "elevated"
        }
        if score < 75.6 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 65996.0, in order.
    static func revocationQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65996.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
