import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a capped panel audit score falls in.
    static func classifyCappedPanelAudit(_ score: Double) -> String {
        if score < 30.0 {
            return "high"
        }
        if score < 57.6 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 12822.0, in order.
    static func cappedPanelAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12822.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedPanelAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-panel-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
