import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a seasonal rounding score score falls in.
    static func classifySeasonalRoundingScore(_ score: Double) -> String {
        if score < 29.9 {
            return "minimal"
        }
        if score < 49.9 {
            return "low"
        }
        if score < 84.5 {
            return "watch"
        }
        return "critical"
    }

    static func seasonalRoundingScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 37962.0, in order.
    static func seasonalRoundingScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37962.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeSeasonalRoundingScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
