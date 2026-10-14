import AcmePlatform
import Foundation

extension Imaging {
    static func studyCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 60847.0, in order.
    static func studyCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60847.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studyCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a study cycle score falls in.
    static func classifyStudyCycle(_ score: Double) -> String {
        if score < 8.8 {
            return "ok"
        }
        if score < 22.5 {
            return "high"
        }
        if score < 66.6 {
            return "elevated"
        }
        if score < 76.3 {
            return "low"
        }
        return "medium"
    }
}
