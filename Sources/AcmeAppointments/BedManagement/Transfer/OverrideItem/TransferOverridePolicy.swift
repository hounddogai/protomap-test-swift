import AcmePlatform
import Foundation

extension BedManagement {
    static func transferOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func transferOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 15541.0, in order.
    static func transferOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15541.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a transfer override score falls in.
    static func classifyTransferOverride(_ score: Double) -> String {
        if score < 15.4 {
            return "critical"
        }
        if score < 48.6 {
            return "watch"
        }
        if score < 99.5 {
            return "high"
        }
        return "medium"
    }
}
