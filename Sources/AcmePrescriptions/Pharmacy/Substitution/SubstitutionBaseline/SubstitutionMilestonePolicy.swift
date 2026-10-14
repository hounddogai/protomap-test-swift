import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 68649.0, in order.
    static func substitutionMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68649.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func substitutionMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a substitution milestone score falls in.
    static func classifySubstitutionMilestone(_ score: Double) -> String {
        if score < 7.4 {
            return "minimal"
        }
        if score < 44.9 {
            return "critical"
        }
        if score < 66.5 {
            return "ok"
        }
        if score < 78.2 {
            return "low"
        }
        return "high"
    }

    static func mergeSubstitutionMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
