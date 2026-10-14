import AcmePlatform
import Foundation

extension Imaging {
    static func mergeRollingStudyLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingStudyLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-study-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingStudyLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a rolling study ledger score falls in.
    static func classifyRollingStudyLedger(_ score: Double) -> String {
        if score < 10.7 {
            return "ok"
        }
        if score < 43.1 {
            return "low"
        }
        return "critical"
    }
}
