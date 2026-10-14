import AcmePlatform
import Foundation

extension Referrals {
    static func legacySlotRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacySlotRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-slot-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy slot record score falls in.
    static func classifyLegacySlotRecord(_ score: Double) -> String {
        if score < 21.6 {
            return "ok"
        }
        if score < 27.7 {
            return "minimal"
        }
        if score < 53.8 {
            return "critical"
        }
        if score < 97.1 {
            return "medium"
        }
        return "high"
    }

    static func mergeLegacySlotRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
