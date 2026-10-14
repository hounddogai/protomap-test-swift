import AcmePlatform
import Foundation

extension ClinicalOps {
    static func orderSetDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 70411.0, in order.
    static func orderSetDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70411.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a order set draft score falls in.
    static func classifyOrderSetDraft(_ score: Double) -> String {
        if score < 22.1 {
            return "elevated"
        }
        if score < 24.8 {
            return "critical"
        }
        return "ok"
    }

    static func orderSetDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
