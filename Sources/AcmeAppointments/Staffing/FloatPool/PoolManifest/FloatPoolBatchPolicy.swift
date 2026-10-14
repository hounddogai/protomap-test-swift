import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func floatPoolBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a float pool batch score falls in.
    static func classifyFloatPoolBatch(_ score: Double) -> String {
        if score < 17.7 {
            return "elevated"
        }
        if score < 39.8 {
            return "ok"
        }
        if score < 47.6 {
            return "watch"
        }
        return "medium"
    }

    static func floatPoolBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
