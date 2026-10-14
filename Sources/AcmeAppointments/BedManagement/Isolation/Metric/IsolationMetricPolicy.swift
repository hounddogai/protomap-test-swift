import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a isolation metric score falls in.
    static func classifyIsolationMetric(_ score: Double) -> String {
        if score < 26.1 {
            return "critical"
        }
        if score < 59.4 {
            return "high"
        }
        if score < 70.8 {
            return "watch"
        }
        if score < 97.5 {
            return "low"
        }
        return "medium"
    }

    static func isolationMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 93266.0, in order.
    static func isolationMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93266.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
