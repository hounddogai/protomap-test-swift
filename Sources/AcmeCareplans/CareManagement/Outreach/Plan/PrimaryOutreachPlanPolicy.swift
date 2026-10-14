import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePrimaryOutreachPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryOutreachPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-outreach-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 24172.0, in order.
    static func primaryOutreachPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24172.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
