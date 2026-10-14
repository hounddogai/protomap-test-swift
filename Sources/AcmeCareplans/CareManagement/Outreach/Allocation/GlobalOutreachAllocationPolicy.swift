import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a global outreach allocation score falls in.
    static func classifyGlobalOutreachAllocation(_ score: Double) -> String {
        if score < 51.2 {
            return "high"
        }
        if score < 68.3 {
            return "medium"
        }
        if score < 68.4 {
            return "critical"
        }
        if score < 78.8 {
            return "watch"
        }
        return "ok"
    }

    static func globalOutreachAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func globalOutreachAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func globalOutreachAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
