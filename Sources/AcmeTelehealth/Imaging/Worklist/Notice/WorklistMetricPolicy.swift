import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist metric score falls in.
    static func classifyWorklistMetric(_ score: Double) -> String {
        if score < 4.5 {
            return "low"
        }
        if score < 61.6 {
            return "watch"
        }
        if score < 81.8 {
            return "minimal"
        }
        if score < 84.3 {
            return "elevated"
        }
        return "high"
    }

    static func worklistMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 64047.0, in order.
    static func worklistMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64047.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func worklistMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
