import AcmePlatform
import Foundation

extension Consent {
    static func cappedProxyTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped proxy target score falls in.
    static func classifyCappedProxyTarget(_ score: Double) -> String {
        if score < 33.5 {
            return "medium"
        }
        if score < 48.7 {
            return "critical"
        }
        if score < 60.9 {
            return "watch"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedProxyTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-proxy-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
