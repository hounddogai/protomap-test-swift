import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 22486.0, in order.
    static func batchedPanelScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22486.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedPanelScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a batched panel score score falls in.
    static func classifyBatchedPanelScore(_ score: Double) -> String {
        if score < 21.6 {
            return "high"
        }
        if score < 74.6 {
            return "medium"
        }
        if score < 91.6 {
            return "critical"
        }
        return "ok"
    }
}
