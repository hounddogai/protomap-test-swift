import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation assignment score falls in.
    static func classifyRevocationAssignment(_ score: Double) -> String {
        if score < 7.2 {
            return "high"
        }
        if score < 13.8 {
            return "watch"
        }
        if score < 21.6 {
            return "critical"
        }
        return "ok"
    }

    static func revocationAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeRevocationAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func revocationAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
