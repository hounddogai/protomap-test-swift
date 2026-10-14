import AcmePlatform
import Foundation

extension BedManagement {
    static func pendingCensusBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a pending census budget score falls in.
    static func classifyPendingCensusBudget(_ score: Double) -> String {
        if score < 29.5 {
            return "critical"
        }
        if score < 85.7 {
            return "watch"
        }
        if score < 92.0 {
            return "high"
        }
        if score < 97.5 {
            return "ok"
        }
        return "elevated"
    }

    static func pendingCensusBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
