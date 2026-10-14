import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a remittance manifest score falls in.
    static func classifyRemittanceManifest(_ score: Double) -> String {
        if score < 8.5 {
            return "high"
        }
        if score < 25.4 {
            return "ok"
        }
        if score < 78.9 {
            return "elevated"
        }
        if score < 79.1 {
            return "watch"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func remittanceManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
