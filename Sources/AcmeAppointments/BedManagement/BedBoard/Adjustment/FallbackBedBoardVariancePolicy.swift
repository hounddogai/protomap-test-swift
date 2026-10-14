import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeFallbackBedBoardVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackBedBoardVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-bed-board-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackBedBoardVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func fallbackBedBoardVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
