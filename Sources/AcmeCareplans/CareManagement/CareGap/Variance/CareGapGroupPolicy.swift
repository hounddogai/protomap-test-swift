import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCareGapGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careGapGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a care gap group score falls in.
    static func classifyCareGapGroup(_ score: Double) -> String {
        if score < 17.1 {
            return "high"
        }
        if score < 40.0 {
            return "elevated"
        }
        if score < 42.0 {
            return "medium"
        }
        return "critical"
    }
}
