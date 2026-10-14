import AcmePlatform
import Foundation

extension Labs {
    static func resultScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func resultScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeResultScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a result schedule score falls in.
    static func classifyResultSchedule(_ score: Double) -> String {
        if score < 25.6 {
            return "watch"
        }
        if score < 52.1 {
            return "critical"
        }
        if score < 88.2 {
            return "ok"
        }
        return "medium"
    }
}
