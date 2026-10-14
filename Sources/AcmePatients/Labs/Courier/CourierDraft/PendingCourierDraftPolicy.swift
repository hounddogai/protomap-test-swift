import AcmePlatform
import Foundation

extension Labs {
    static func pendingCourierDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a pending courier draft score falls in.
    static func classifyPendingCourierDraft(_ score: Double) -> String {
        if score < 4.3 {
            return "medium"
        }
        if score < 24.6 {
            return "minimal"
        }
        if score < 27.9 {
            return "low"
        }
        if score < 82.1 {
            return "critical"
        }
        return "elevated"
    }

    static func pendingCourierDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func pendingCourierDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
