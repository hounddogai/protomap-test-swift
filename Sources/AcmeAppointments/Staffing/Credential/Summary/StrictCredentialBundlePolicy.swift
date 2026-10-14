import AcmePlatform
import Foundation

extension Staffing {
    static func strictCredentialBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func strictCredentialBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictCredentialBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-credential-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict credential bundle score falls in.
    static func classifyStrictCredentialBundle(_ score: Double) -> String {
        if score < 50.2 {
            return "medium"
        }
        if score < 71.6 {
            return "watch"
        }
        if score < 86.4 {
            return "critical"
        }
        return "elevated"
    }
}
