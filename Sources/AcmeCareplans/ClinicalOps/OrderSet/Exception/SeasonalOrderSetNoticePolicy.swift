import AcmePlatform
import Foundation

extension ClinicalOps {
    static func seasonalOrderSetNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeSeasonalOrderSetNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalOrderSetNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-order-set-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalOrderSetNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
