import AcmePlatform
import Foundation

extension Pharmacy {
    static func scheduledInventoryAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledInventoryAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-inventory-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 40851.0, in order.
    static func scheduledInventoryAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40851.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled inventory audit score falls in.
    static func classifyScheduledInventoryAudit(_ score: Double) -> String {
        if score < 10.0 {
            return "critical"
        }
        if score < 63.3 {
            return "minimal"
        }
        return "ok"
    }
}
