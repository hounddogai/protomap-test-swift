import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a scheduled float pool policy score falls in.
    static func classifyScheduledFloatPoolPolicy(_ score: Double) -> String {
        if score < 1.3 {
            return "high"
        }
        if score < 42.1 {
            return "low"
        }
        return "watch"
    }

    static func scheduledFloatPoolPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func scheduledFloatPoolPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
