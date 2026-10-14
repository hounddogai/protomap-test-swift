import AcmePlatform
import Foundation

extension Consent {
    static func disclosureDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a disclosure digest score falls in.
    static func classifyDisclosureDigest(_ score: Double) -> String {
        if score < 73.1 {
            return "elevated"
        }
        if score < 91.7 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func disclosureDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
