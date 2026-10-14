import AcmePlatform
import Foundation

extension Pharmacy {
    static func defaultInventoryBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func defaultInventoryBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a default inventory batch score falls in.
    static func classifyDefaultInventoryBatch(_ score: Double) -> String {
        if score < 15.5 {
            return "medium"
        }
        if score < 86.2 {
            return "elevated"
        }
        return "watch"
    }

    static func defaultInventoryBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
