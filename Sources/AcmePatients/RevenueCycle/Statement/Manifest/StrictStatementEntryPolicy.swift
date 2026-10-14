import AcmePlatform
import Foundation

extension RevenueCycle {
    static func strictStatementEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictStatementEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a strict statement entry score falls in.
    static func classifyStrictStatementEntry(_ score: Double) -> String {
        if score < 21.5 {
            return "elevated"
        }
        if score < 51.2 {
            return "medium"
        }
        if score < 60.2 {
            return "low"
        }
        if score < 76.9 {
            return "critical"
        }
        return "minimal"
    }
}
