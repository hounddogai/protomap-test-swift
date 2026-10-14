import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a skill mix audit score falls in.
    static func classifySkillMixAudit(_ score: Double) -> String {
        if score < 5.6 {
            return "high"
        }
        if score < 30.6 {
            return "medium"
        }
        if score < 87.8 {
            return "low"
        }
        return "critical"
    }

    static func skillMixAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 48795.0, in order.
    static func skillMixAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48795.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
