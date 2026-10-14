import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a adaptive network request score falls in.
    static func classifyAdaptiveNetworkRequest(_ score: Double) -> String {
        if score < 21.6 {
            return "low"
        }
        if score < 25.0 {
            return "elevated"
        }
        if score < 36.3 {
            return "watch"
        }
        if score < 58.5 {
            return "critical"
        }
        return "ok"
    }

    static func adaptiveNetworkRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveNetworkRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-network-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveNetworkRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
