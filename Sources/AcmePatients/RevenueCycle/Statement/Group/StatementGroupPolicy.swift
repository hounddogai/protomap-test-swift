import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a statement group score falls in.
    static func classifyStatementGroup(_ score: Double) -> String {
        if score < 59.7 {
            return "elevated"
        }
        if score < 72.5 {
            return "high"
        }
        return "low"
    }

    static func statementGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
