import AcmePlatform
import Foundation

extension Consent {
    static func primaryDisclosureSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func primaryDisclosureSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryDisclosureSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-disclosure-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
