import AcmePlatform
import Foundation

extension Labs {
    static func rollingAccessionBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func rollingAccessionBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 3.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func rollingAccessionBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a rolling accession batch score falls in.
    static func classifyRollingAccessionBatch(_ score: Double) -> String {
        if score < 3.9 {
            return "high"
        }
        if score < 51.7 {
            return "low"
        }
        if score < 61.1 {
            return "watch"
        }
        if score < 70.3 {
            return "elevated"
        }
        return "ok"
    }
}
