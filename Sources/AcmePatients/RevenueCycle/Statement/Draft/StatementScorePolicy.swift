import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeStatementScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a statement score score falls in.
    static func classifyStatementScore(_ score: Double) -> String {
        if score < 2.1 {
            return "watch"
        }
        if score < 69.2 {
            return "medium"
        }
        return "ok"
    }

    static func statementScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func statementScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
