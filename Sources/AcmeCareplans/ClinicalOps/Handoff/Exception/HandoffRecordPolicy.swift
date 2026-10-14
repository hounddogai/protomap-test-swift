import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a handoff record score falls in.
    static func classifyHandoffRecord(_ score: Double) -> String {
        if score < 39.7 {
            return "ok"
        }
        if score < 87.7 {
            return "medium"
        }
        if score < 96.6 {
            return "elevated"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 76489.0, in order.
    static func handoffRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76489.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func handoffRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
