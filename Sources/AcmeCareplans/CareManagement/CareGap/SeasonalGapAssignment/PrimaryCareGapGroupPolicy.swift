import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryCareGapGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a primary care gap group score falls in.
    static func classifyPrimaryCareGapGroup(_ score: Double) -> String {
        if score < 12.6 {
            return "minimal"
        }
        if score < 36.4 {
            return "medium"
        }
        if score < 39.9 {
            return "critical"
        }
        if score < 61.0 {
            return "ok"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryCareGapGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-care-gap-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePrimaryCareGapGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
