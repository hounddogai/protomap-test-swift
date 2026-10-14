import AcmePlatform
import Foundation

extension Staffing {
    static func cappedShiftMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped shift metric score falls in.
    static func classifyCappedShiftMetric(_ score: Double) -> String {
        if score < 27.9 {
            return "elevated"
        }
        if score < 79.4 {
            return "ok"
        }
        if score < 85.4 {
            return "medium"
        }
        return "minimal"
    }

    static func cappedShiftMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 9120.0, in order.
    static func cappedShiftMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9120.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
