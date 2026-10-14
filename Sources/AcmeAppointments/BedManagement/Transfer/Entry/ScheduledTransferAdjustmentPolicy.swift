import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a scheduled transfer adjustment score falls in.
    static func classifyScheduledTransferAdjustment(_ score: Double) -> String {
        if score < 68.8 {
            return "watch"
        }
        if score < 80.3 {
            return "low"
        }
        if score < 88.7 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 99001.0, in order.
    static func scheduledTransferAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99001.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledTransferAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-transfer-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledTransferAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
