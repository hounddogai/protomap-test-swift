import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a default assessment entry score falls in.
    static func classifyDefaultAssessmentEntry(_ score: Double) -> String {
        if score < 3.1 {
            return "elevated"
        }
        if score < 15.7 {
            return "ok"
        }
        if score < 65.5 {
            return "critical"
        }
        if score < 87.3 {
            return "minimal"
        }
        return "watch"
    }

    static func defaultAssessmentEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func defaultAssessmentEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultAssessmentEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-assessment-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
