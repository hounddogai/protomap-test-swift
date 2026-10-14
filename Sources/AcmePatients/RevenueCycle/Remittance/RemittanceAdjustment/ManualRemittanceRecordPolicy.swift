import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualRemittanceRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualRemittanceRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-remittance-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeManualRemittanceRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
