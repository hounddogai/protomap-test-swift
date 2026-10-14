import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 22126.0, in order.
    static func pendingAcuityPlanMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22126.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending acuity plan milestone score falls in.
    static func classifyPendingAcuityPlanMilestone(_ score: Double) -> String {
        if score < 6.2 {
            return "medium"
        }
        if score < 16.7 {
            return "minimal"
        }
        if score < 66.8 {
            return "watch"
        }
        if score < 90.4 {
            return "ok"
        }
        return "low"
    }

    static func pendingAcuityPlanMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func pendingAcuityPlanMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
