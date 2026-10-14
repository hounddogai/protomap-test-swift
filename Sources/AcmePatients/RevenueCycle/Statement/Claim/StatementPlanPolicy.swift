import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a statement plan score falls in.
    static func classifyStatementPlan(_ score: Double) -> String {
        if score < 44.7 {
            return "elevated"
        }
        if score < 50.2 {
            return "ok"
        }
        return "watch"
    }

    static func statementPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeStatementPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
