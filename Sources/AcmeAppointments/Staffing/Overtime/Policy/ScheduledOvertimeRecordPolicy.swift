import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledOvertimeRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-overtime-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 26188.0, in order.
    static func scheduledOvertimeRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26188.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
