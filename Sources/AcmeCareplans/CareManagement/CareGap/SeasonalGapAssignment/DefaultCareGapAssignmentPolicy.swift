import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeDefaultCareGapAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default care gap assignment score falls in.
    static func classifyDefaultCareGapAssignment(_ score: Double) -> String {
        if score < 21.0 {
            return "low"
        }
        if score < 52.4 {
            return "elevated"
        }
        if score < 59.0 {
            return "watch"
        }
        return "medium"
    }

    static func defaultCareGapAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCareGapAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-care-gap-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
