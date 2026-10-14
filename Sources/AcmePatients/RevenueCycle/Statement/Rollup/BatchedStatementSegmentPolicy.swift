import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedStatementSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-statement-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeBatchedStatementSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
