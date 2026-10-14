import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a primary statement record score falls in.
    static func classifyPrimaryStatementRecord(_ score: Double) -> String {
        if score < 19.6 {
            return "elevated"
        }
        if score < 74.9 {
            return "minimal"
        }
        if score < 88.0 {
            return "low"
        }
        if score < 99.4 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryStatementRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-statement-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryStatementRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
