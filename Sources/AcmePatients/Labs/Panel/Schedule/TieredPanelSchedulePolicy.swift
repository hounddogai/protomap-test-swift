import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a tiered panel schedule score falls in.
    static func classifyTieredPanelSchedule(_ score: Double) -> String {
        if score < 33.1 {
            return "elevated"
        }
        if score < 60.7 {
            return "ok"
        }
        return "low"
    }

    static func tieredPanelScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredPanelScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
