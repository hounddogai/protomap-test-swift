import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a recall window score falls in.
    static func classifyRecallWindow(_ score: Double) -> String {
        if score < 17.1 {
            return "critical"
        }
        if score < 65.2 {
            return "low"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 23822.0, in order.
    static func recallWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23822.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func recallWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func recallWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
