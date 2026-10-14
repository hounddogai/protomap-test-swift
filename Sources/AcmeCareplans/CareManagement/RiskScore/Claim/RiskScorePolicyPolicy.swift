import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScorePolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a risk score policy score falls in.
    static func classifyRiskScorePolicy(_ score: Double) -> String {
        if score < 13.3 {
            return "low"
        }
        if score < 23.0 {
            return "ok"
        }
        if score < 96.0 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 74972.0, in order.
    static func riskScorePolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74972.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func riskScorePolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
