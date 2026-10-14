import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a inventory metric score falls in.
    static func classifyInventoryMetric(_ score: Double) -> String {
        if score < 5.6 {
            return "ok"
        }
        if score < 52.1 {
            return "critical"
        }
        return "low"
    }

    static func inventoryMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 17185.0, in order.
    static func inventoryMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17185.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
