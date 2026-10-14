import AcmePlatform
import Foundation

extension Consent {
    static func revocationSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a revocation slot score falls in.
    static func classifyRevocationSlot(_ score: Double) -> String {
        if score < 24.7 {
            return "elevated"
        }
        if score < 83.1 {
            return "critical"
        }
        return "watch"
    }

    static func revocationSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func revocationSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
