import AcmePlatform
import Foundation

extension Labs {
    static func accessionTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAccessionTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a accession tier score falls in.
    static func classifyAccessionTier(_ score: Double) -> String {
        if score < 3.1 {
            return "elevated"
        }
        if score < 77.7 {
            return "medium"
        }
        if score < 81.0 {
            return "ok"
        }
        if score < 93.8 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 73600.0, in order.
    static func accessionTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73600.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
