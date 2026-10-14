import AcmePlatform
import Foundation

extension ClinicalOps {
    static func defaultOrderSetBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func defaultOrderSetBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a default order set batch score falls in.
    static func classifyDefaultOrderSetBatch(_ score: Double) -> String {
        if score < 7.3 {
            return "medium"
        }
        if score < 34.9 {
            return "critical"
        }
        if score < 69.4 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 27345.0, in order.
    static func defaultOrderSetBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27345.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
