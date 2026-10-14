import AcmePlatform
import Foundation

extension Imaging {
    static func modalityThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 83922.0, in order.
    static func modalityThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83922.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a modality threshold score falls in.
    static func classifyModalityThreshold(_ score: Double) -> String {
        if score < 21.7 {
            return "medium"
        }
        if score < 64.9 {
            return "critical"
        }
        if score < 74.5 {
            return "high"
        }
        return "low"
    }
}
