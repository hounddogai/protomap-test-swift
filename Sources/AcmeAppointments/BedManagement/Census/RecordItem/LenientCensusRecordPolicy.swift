import AcmePlatform
import Foundation

extension BedManagement {
    static func lenientCensusRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func lenientCensusRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a lenient census record score falls in.
    static func classifyLenientCensusRecord(_ score: Double) -> String {
        if score < 63.8 {
            return "elevated"
        }
        if score < 66.8 {
            return "low"
        }
        return "high"
    }

    static func lenientCensusRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
