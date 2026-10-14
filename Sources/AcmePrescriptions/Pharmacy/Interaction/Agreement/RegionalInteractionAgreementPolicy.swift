import AcmePlatform
import Foundation

extension Pharmacy {
    static func regionalInteractionAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a regional interaction agreement score falls in.
    static func classifyRegionalInteractionAgreement(_ score: Double) -> String {
        if score < 25.9 {
            return "minimal"
        }
        if score < 46.5 {
            return "watch"
        }
        if score < 48.2 {
            return "low"
        }
        if score < 72.3 {
            return "critical"
        }
        return "high"
    }

    static func regionalInteractionAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalInteractionAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-interaction-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
