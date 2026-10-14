import AcmePlatform
import Foundation

extension Labs {
    static func panelAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a panel audit score falls in.
    static func classifyPanelAudit(_ score: Double) -> String {
        if score < 31.1 {
            return "high"
        }
        if score < 93.6 {
            return "watch"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 63936.0, in order.
    static func panelAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
