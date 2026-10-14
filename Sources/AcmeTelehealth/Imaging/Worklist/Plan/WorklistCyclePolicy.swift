import AcmePlatform
import Foundation

extension Imaging {
    static func worklistCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func worklistCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a worklist cycle score falls in.
    static func classifyWorklistCycle(_ score: Double) -> String {
        if score < 35.1 {
            return "low"
        }
        if score < 36.9 {
            return "elevated"
        }
        if score < 77.9 {
            return "high"
        }
        if score < 89.1 {
            return "critical"
        }
        return "medium"
    }
}
