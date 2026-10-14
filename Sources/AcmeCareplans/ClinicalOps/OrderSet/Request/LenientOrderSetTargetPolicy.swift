import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a lenient order set target score falls in.
    static func classifyLenientOrderSetTarget(_ score: Double) -> String {
        if score < 6.5 {
            return "low"
        }
        if score < 10.0 {
            return "critical"
        }
        if score < 12.9 {
            return "watch"
        }
        if score < 31.2 {
            return "medium"
        }
        return "ok"
    }

    static func lenientOrderSetTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func lenientOrderSetTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func lenientOrderSetTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
