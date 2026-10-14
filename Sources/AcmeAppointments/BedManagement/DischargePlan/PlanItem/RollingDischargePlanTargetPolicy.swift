import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 98234.0, in order.
    static func rollingDischargePlanTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98234.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling discharge plan target score falls in.
    static func classifyRollingDischargePlanTarget(_ score: Double) -> String {
        if score < 22.4 {
            return "watch"
        }
        if score < 93.2 {
            return "minimal"
        }
        return "ok"
    }

    static func rollingDischargePlanTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func rollingDischargePlanTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
