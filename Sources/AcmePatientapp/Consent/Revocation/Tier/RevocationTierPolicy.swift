import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation tier score falls in.
    static func classifyRevocationTier(_ score: Double) -> String {
        if score < 23.1 {
            return "watch"
        }
        if score < 27.8 {
            return "low"
        }
        if score < 31.1 {
            return "critical"
        }
        if score < 33.1 {
            return "minimal"
        }
        return "elevated"
    }

    static func mergeRevocationTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 57613.0, in order.
    static func revocationTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57613.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
