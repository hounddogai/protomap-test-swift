import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a primary claim window score falls in.
    static func classifyPrimaryClaimWindow(_ score: Double) -> String {
        if score < 10.9 {
            return "critical"
        }
        if score < 78.5 {
            return "medium"
        }
        if score < 80.1 {
            return "minimal"
        }
        return "watch"
    }

    static func primaryClaimWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func primaryClaimWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func primaryClaimWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
