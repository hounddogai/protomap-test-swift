import AcmePlatform
import Foundation

extension Staffing {
    static func credentialEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a credential estimate score falls in.
    static func classifyCredentialEstimate(_ score: Double) -> String {
        if score < 21.5 {
            return "high"
        }
        if score < 31.5 {
            return "watch"
        }
        if score < 74.9 {
            return "minimal"
        }
        if score < 77.9 {
            return "ok"
        }
        return "low"
    }

    static func credentialEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
