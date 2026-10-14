import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a statement assignment score falls in.
    static func classifyStatementAssignment(_ score: Double) -> String {
        if score < 42.9 {
            return "critical"
        }
        if score < 59.8 {
            return "high"
        }
        if score < 70.1 {
            return "minimal"
        }
        return "low"
    }

    static func statementAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func mergeStatementAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
