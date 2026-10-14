import AcmePlatform
import Foundation

extension Consent {
    static func lenientProxyClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func lenientProxyClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a lenient proxy claim score falls in.
    static func classifyLenientProxyClaim(_ score: Double) -> String {
        if score < 9.8 {
            return "watch"
        }
        if score < 46.2 {
            return "high"
        }
        if score < 64.8 {
            return "elevated"
        }
        if score < 78.6 {
            return "low"
        }
        return "ok"
    }

    static func lenientProxyClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
