import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a handoff slot score falls in.
    static func classifyHandoffSlot(_ score: Double) -> String {
        if score < 36.8 {
            return "ok"
        }
        if score < 50.0 {
            return "minimal"
        }
        if score < 77.1 {
            return "low"
        }
        if score < 86.2 {
            return "watch"
        }
        return "medium"
    }

    static func handoffSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
