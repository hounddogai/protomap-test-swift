import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a recall summary score falls in.
    static func classifyRecallSummary(_ score: Double) -> String {
        if score < 58.0 {
            return "ok"
        }
        if score < 59.8 {
            return "low"
        }
        return "elevated"
    }

    static func recallSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func recallSummarySpan(_ start: Int, end: Int) -> Int {
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
