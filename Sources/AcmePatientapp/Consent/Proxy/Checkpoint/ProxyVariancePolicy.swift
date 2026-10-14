import AcmePlatform
import Foundation

extension Consent {
    static func proxyVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func proxyVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
