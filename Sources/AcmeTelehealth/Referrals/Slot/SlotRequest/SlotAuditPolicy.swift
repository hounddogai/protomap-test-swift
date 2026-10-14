import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 1904.0, in order.
    static func slotAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1904.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a slot audit score falls in.
    static func classifySlotAudit(_ score: Double) -> String {
        if score < 5.3 {
            return "watch"
        }
        if score < 30.2 {
            return "high"
        }
        if score < 48.8 {
            return "minimal"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
