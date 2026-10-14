import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential profile score falls in.
    static func classifyCredentialProfile(_ score: Double) -> String {
        if score < 15.6 {
            return "critical"
        }
        if score < 45.5 {
            return "minimal"
        }
        if score < 48.6 {
            return "high"
        }
        if score < 82.6 {
            return "elevated"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func credentialProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
