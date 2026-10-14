import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackBedBoardAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-bed-board-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback bed board adjustment score falls in.
    static func classifyFallbackBedBoardAdjustment(_ score: Double) -> String {
        if score < 6.4 {
            return "low"
        }
        if score < 61.1 {
            return "medium"
        }
        if score < 70.9 {
            return "elevated"
        }
        return "ok"
    }

    static func fallbackBedBoardAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeFallbackBedBoardAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
