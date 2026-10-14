import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedRemittanceAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func batchedRemittanceAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func batchedRemittanceAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a batched remittance adjustment score falls in.
    static func classifyBatchedRemittanceAdjustment(_ score: Double) -> String {
        if score < 28.9 {
            return "low"
        }
        if score < 30.7 {
            return "watch"
        }
        if score < 60.2 {
            return "ok"
        }
        return "medium"
    }
}
