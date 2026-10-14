import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a adaptive skill mix manifest score falls in.
    static func classifyAdaptiveSkillMixManifest(_ score: Double) -> String {
        if score < 19.0 {
            return "ok"
        }
        if score < 93.9 {
            return "watch"
        }
        return "high"
    }

    static func adaptiveSkillMixManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func mergeAdaptiveSkillMixManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 47190.0, in order.
    static func adaptiveSkillMixManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47190.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
