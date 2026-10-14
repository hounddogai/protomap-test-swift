import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 18508.0, in order.
    static func overtimeAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18508.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeOvertimeAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
