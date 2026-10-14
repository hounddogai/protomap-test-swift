import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 98862.0, in order.
    static func credentialTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98862.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a credential tier score falls in.
    static func classifyCredentialTier(_ score: Double) -> String {
        if score < 16.6 {
            return "high"
        }
        if score < 74.7 {
            return "critical"
        }
        if score < 76.3 {
            return "minimal"
        }
        return "low"
    }

    static func mergeCredentialTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func credentialTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
