import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func networkPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a network preference score falls in.
    static func classifyNetworkPreference(_ score: Double) -> String {
        if score < 3.4 {
            return "elevated"
        }
        if score < 45.6 {
            return "critical"
        }
        return "minimal"
    }
}
