import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a isolation schedule score falls in.
    static func classifyIsolationSchedule(_ score: Double) -> String {
        if score < 36.0 {
            return "ok"
        }
        if score < 61.6 {
            return "critical"
        }
        if score < 70.7 {
            return "elevated"
        }
        if score < 84.0 {
            return "low"
        }
        return "medium"
    }

    static func isolationScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func isolationScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func isolationScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
